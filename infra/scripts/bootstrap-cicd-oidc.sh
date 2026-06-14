#!/usr/bin/env bash
#
# bootstrap-cicd-oidc.sh
#
# Provisions the keyless (OIDC) trust + GitHub configuration that the infra
# CI/CD workflows expect. Idempotent and portable: re-running converges to the
# same state, and every input is overridable via environment variables so the
# script works for any repo / subscription / state backend.
#
# What it does:
#   1. Ensures an Entra app registration + service principal exists to act as
#      the deploy identity (one identity, scoped per-environment via subjects).
#   2. Adds a federated credential per environment so GitHub Actions can log in
#      without secrets:  repo:<owner>/<repo>:environment:<env>
#   3. Grants the SP RBAC:
#        - "Storage Blob Data Contributor" on the tfstate storage account
#        - a deploy role (default Contributor) at subscription scope
#   4. Creates the GitHub Environments and (for prod) a required reviewer.
#   5. Sets the per-environment Actions *variables* the workflows read
#      (AZURE_*, TFSTATE_*). Secrets are intentionally NOT set here.
#
# Requires: az CLI (logged in), gh CLI (logged in), jq
#
# Usage:
#   ./bootstrap-cicd-oidc.sh                      # uses current az/gh context
#   ENVIRONMENTS="dev prod" ./bootstrap-cicd-oidc.sh
#   PROD_REVIEWER="octocat" ./bootstrap-cicd-oidc.sh
#
# Key environment variables (all optional unless noted):
#   REPO                GitHub "owner/repo". Default: `gh repo view`.
#   ENVIRONMENTS        Space-separated list. Default: "dev prod".
#   APPROVAL_ENVS       Envs that require a reviewer. Default: "prod".
#   PROD_REVIEWER       GitHub login to set as required reviewer on APPROVAL_ENVS.
#                       Default: the authenticated gh user.
#   APP_NAME            Entra app display name. Default: "<repo>-cicd".
#   SUBSCRIPTION_ID     Default: current `az account show`.
#   TENANT_ID           Default: current `az account show`.
#   DEPLOY_ROLE         Subscription-scope role for applies. Default: "Contributor".
#   TFSTATE_RESOURCE_GROUP   Default: "rg-tfstate".
#   TFSTATE_STORAGE_ACCOUNT  Default: "sttfstate31327".
#   TFSTATE_CONTAINER        Default: "tfstate".
#   DRY_RUN             "true" prints actions without changing anything.

set -euo pipefail

# --- Helpers -----------------------------------------------------------------
log()  { echo "==> $*" >&2; }
warn() { echo "WARN: $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }
run()  { if [[ "${DRY_RUN:-false}" == "true" ]]; then echo "DRY-RUN: $*" >&2; else "$@"; fi; }

for bin in az gh jq; do
  command -v "$bin" >/dev/null || die "$bin not found on PATH"
done

# --- Resolve context ---------------------------------------------------------
REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
[[ -n "$REPO" ]] || die "could not resolve REPO; set REPO=owner/repo"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
TENANT_ID="${TENANT_ID:-$(az account show --query tenantId -o tsv)}"

ENVIRONMENTS="${ENVIRONMENTS:-dev prod}"
APPROVAL_ENVS="${APPROVAL_ENVS:-prod}"
PROD_REVIEWER="${PROD_REVIEWER:-$(gh api user -q .login)}"
APP_NAME="${APP_NAME:-${REPO##*/}-cicd}"
DEPLOY_ROLE="${DEPLOY_ROLE:-Contributor}"

TFSTATE_RESOURCE_GROUP="${TFSTATE_RESOURCE_GROUP:-rg-tfstate}"
TFSTATE_STORAGE_ACCOUNT="${TFSTATE_STORAGE_ACCOUNT:-sttfstate31327}"
TFSTATE_CONTAINER="${TFSTATE_CONTAINER:-tfstate}"

log "Repo:            $REPO"
log "Subscription:    $SUBSCRIPTION_ID"
log "Tenant:          $TENANT_ID"
log "Environments:    $ENVIRONMENTS  (approval: $APPROVAL_ENVS)"
log "App name:        $APP_NAME"
log "Deploy role:     $DEPLOY_ROLE (subscription scope)"
log "State account:   $TFSTATE_STORAGE_ACCOUNT / $TFSTATE_CONTAINER (rg: $TFSTATE_RESOURCE_GROUP)"
[[ "${DRY_RUN:-false}" == "true" ]] && log "DRY_RUN enabled — no changes will be made"
echo >&2

# --- 1. Entra app + service principal (idempotent) ---------------------------
APP_ID="$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)"
if [[ -z "$APP_ID" ]]; then
  log "Creating Entra app '$APP_NAME'"
  APP_ID="$(run az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
else
  log "Entra app '$APP_NAME' exists ($APP_ID)"
fi
[[ "${DRY_RUN:-false}" == "true" && -z "$APP_ID" ]] && APP_ID="<dry-run-app-id>"

if [[ "${DRY_RUN:-false}" == "true" && "$APP_ID" == "<dry-run-app-id>" ]]; then
  log "Service principal lookup skipped (dry run with placeholder APP_ID)"
  SP_OID="<dry-run-sp-oid>"
else
  if [[ -z "$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null || true)" ]]; then
    log "Creating service principal for $APP_ID"
    run az ad sp create --id "$APP_ID" >/dev/null
  else
    log "Service principal exists for $APP_ID"
  fi
  SP_OID="$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null || true)"
  [[ -z "$SP_OID" ]] && SP_OID="<dry-run-sp-oid>"
fi

# --- 2. Federated credentials per environment --------------------------------
for env in $ENVIRONMENTS; do
  fic_name="gh-${env}"
  subject="repo:${REPO}:environment:${env}"
  if [[ "${DRY_RUN:-false}" == "true" && "$APP_ID" == "<dry-run-app-id>" ]]; then
    existing=""
  else
    existing="$(az ad app federated-credential list --id "$APP_ID" \
      --query "[?subject=='${subject}'].name | [0]" -o tsv 2>/dev/null || true)"
  fi
  if [[ -n "$existing" ]]; then
    log "Federated credential for env '$env' exists ($existing)"
  else
    log "Adding federated credential for env '$env' (subject: $subject)"
    run az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "${fic_name}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${subject}",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)" >/dev/null
  fi
done

# --- 3. RBAC -----------------------------------------------------------------
SA_ID="$(az storage account show \
  --name "$TFSTATE_STORAGE_ACCOUNT" \
  --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --query id -o tsv 2>/dev/null || true)"
if [[ -n "$SA_ID" ]]; then
  log "Granting 'Storage Blob Data Contributor' on state account"
  run az role assignment create \
    --assignee-object-id "$SP_OID" --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Contributor" --scope "$SA_ID" >/dev/null 2>&1 \
    || warn "state RBAC may already exist (ignored)"
else
  warn "state storage account not found; skipping state RBAC"
fi

log "Granting '$DEPLOY_ROLE' at subscription scope"
run az role assignment create \
  --assignee-object-id "$SP_OID" --assignee-principal-type ServicePrincipal \
  --role "$DEPLOY_ROLE" --scope "/subscriptions/${SUBSCRIPTION_ID}" >/dev/null 2>&1 \
  || warn "deploy RBAC may already exist (ignored)"

# --- 4 & 5. GitHub environments, reviewers, and variables --------------------
in_list() { local n="$1"; shift; for x in $*; do [[ "$x" == "$n" ]] && return 0; done; return 1; }

for env in $ENVIRONMENTS; do
  log "Configuring GitHub environment '$env'"
  if in_list "$env" "$APPROVAL_ENVS"; then
    reviewer_id="$(gh api "users/${PROD_REVIEWER}" -q .id 2>/dev/null || true)"
    if [[ -n "$reviewer_id" ]]; then
      log "  requiring reviewer: $PROD_REVIEWER"
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "DRY-RUN: PUT environments/${env} with reviewer ${PROD_REVIEWER}" >&2
      else
        printf '{"reviewers":[{"type":"User","id":%s}]}' "$reviewer_id" \
          | gh api -X PUT "repos/${REPO}/environments/${env}" --input - >/dev/null
      fi
    else
      warn "  reviewer '$PROD_REVIEWER' not found; creating env without reviewer"
      run gh api -X PUT "repos/${REPO}/environments/${env}" --input /dev/null >/dev/null
    fi
  else
    run gh api -X PUT "repos/${REPO}/environments/${env}" --input /dev/null >/dev/null
  fi

  # Per-environment Actions variables consumed by the workflows.
  set_var() {
    run gh variable set "$1" --env "$env" --repo "$REPO" --body "$2" >/dev/null \
      && log "  var $1 set" || warn "  failed to set var $1"
  }
  set_var AZURE_CLIENT_ID "$APP_ID"
  set_var AZURE_TENANT_ID "$TENANT_ID"
  set_var AZURE_SUBSCRIPTION_ID "$SUBSCRIPTION_ID"
  set_var TFSTATE_RESOURCE_GROUP "$TFSTATE_RESOURCE_GROUP"
  set_var TFSTATE_STORAGE_ACCOUNT "$TFSTATE_STORAGE_ACCOUNT"
  set_var TFSTATE_CONTAINER "$TFSTATE_CONTAINER"
done

echo >&2
log "Done. Next steps:"
log " - Add any environment SECRETS your stack needs (e.g. DB passwords) and"
log "   map them to TF_VAR_* in .github/workflows/terraform.yml."
log " - Confirm reviewers/branch protection in the repo's Settings."
log " - RBAC propagation can take a minute before the first run succeeds."
