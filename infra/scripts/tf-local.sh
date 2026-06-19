#!/usr/bin/env bash
#
# tf-local.sh
#
# Local, READ-ONLY Terraform helper for the platform stack. It mirrors how
# .github/workflows/terraform.yml initializes the backend, but authenticates
# with your `az` CLI session instead of CI's OIDC token.
#
# It can ONLY validate or plan. There is deliberately no apply path: the
# pipelines (infra-cd) are the only acceptable way to change state.
#
#   validate         Offline fmt + validate. No Azure creds, no state access.
#   plan <env>       Read-only plan against <env> state. Requires `az login`.
#
# Backend coordinates are read at runtime from the GitHub Actions *variables*
# the workflows use (via `gh`), so nothing is hardcoded or duplicated here.
# Override any of them with TFSTATE_RESOURCE_GROUP / TFSTATE_STORAGE_ACCOUNT /
# TFSTATE_CONTAINER if `gh` is unavailable.
#
# Usage:
#   ./scripts/tf-local.sh validate
#   ./scripts/tf-local.sh plan dev
#   ./scripts/tf-local.sh plan prod -- -no-color   # extra args after `--`
#
# Requires: terraform, az (for plan), gh (for plan, unless TFSTATE_* are set).

set -euo pipefail

# --- Locations ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$SCRIPT_DIR/../stacks/platform"
INFRA_DIR="$SCRIPT_DIR/.."

# --- Helpers -----------------------------------------------------------------
log()  { echo "==> $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null || die "$1 not found on PATH"; }

usage() {
  cat >&2 <<'EOF'
Usage:
  tf-local.sh validate            Offline fmt + validate (no creds, no state)
  tf-local.sh plan <env>          Read-only plan against <env> state

This helper never applies. State changes go through the pipelines only.
EOF
  exit 2
}

# --- Commands ----------------------------------------------------------------
cmd_validate() {
  need terraform
  log "fmt check (whole infra tree)"
  terraform -chdir="$INFRA_DIR" fmt -check -recursive

  log "offline init (-backend=false)"
  terraform -chdir="$STACK_DIR" init -backend=false -input=false >/dev/null

  local staged_tfvars="$STACK_DIR/terraform.tfvars"
  local backup=""
  if [[ -f "$staged_tfvars" ]]; then
    backup="$(mktemp)"
    cp "$staged_tfvars" "$backup"
  fi
  trap 'if [[ -n "$backup" ]]; then mv "$backup" "$staged_tfvars"; else rm -f "$staged_tfvars"; fi' RETURN

  cp "$STACK_DIR/environments/dev.tfvars" "$staged_tfvars"

  log "validate (staged dev tfvars)"
  terraform -chdir="$STACK_DIR" validate
  rm -f "$staged_tfvars"
  trap - RETURN
}

cmd_plan() {
  local env="${1:-}"; shift || true
  [[ -n "$env" ]] || { echo "ERROR: plan requires an environment (dev|prod)" >&2; usage; }
  case "$env" in dev|prod) ;; *) die "unknown environment '$env' (expected dev|prod)";; esac
  [[ "${1:-}" == "--" ]] && shift || true

  need terraform
  need az
  az account show >/dev/null 2>&1 || die "not logged in. Run: az login --scope https://storage.azure.com/.default"

  # Backend coordinates: prefer env overrides, else read the same Actions
  # variables CI uses. Never hardcoded.
  local rg="${TFSTATE_RESOURCE_GROUP:-}" sa="${TFSTATE_STORAGE_ACCOUNT:-}" ct="${TFSTATE_CONTAINER:-}"
  if [[ -z "$rg" || -z "$sa" || -z "$ct" ]]; then
    need gh
    log "reading TFSTATE_* from GitHub env '$env'"
    local kv; kv="$(gh variable list --env "$env" --json name,value \
      --jq '.[] | select(.name|startswith("TFSTATE")) | "\(.name)=\(.value)"' 2>/dev/null)" \
      || die "could not read Actions variables via gh (set TFSTATE_* to override)"
    rg="${rg:-$(sed -n 's/^TFSTATE_RESOURCE_GROUP=//p'  <<<"$kv")}"
    sa="${sa:-$(sed -n 's/^TFSTATE_STORAGE_ACCOUNT=//p' <<<"$kv")}"
    ct="${ct:-$(sed -n 's/^TFSTATE_CONTAINER=//p'       <<<"$kv")}"
  fi
  [[ -n "$rg" && -n "$sa" && -n "$ct" ]] || die "incomplete backend coordinates (rg=$rg sa=$sa ct=$ct)"

  local sub tenant
  sub="$(az account show --query id -o tsv)"
  tenant="$(az account show --query tenantId -o tsv)"

  log "init backend  rg=$rg sa=$sa ct=$ct key=$env/terminal-velocity.tfstate (az auth)"
  terraform -chdir="$STACK_DIR" init -input=false -reconfigure \
    -backend-config="resource_group_name=$rg" \
    -backend-config="storage_account_name=$sa" \
    -backend-config="container_name=$ct" \
    -backend-config="key=$env/terminal-velocity.tfstate" \
    -backend-config="use_oidc=false" >/dev/null

  log "plan ($env) — read-only, no -out, cannot be applied"
  terraform -chdir="$STACK_DIR" plan -input=false \
    -var-file="environments/${env}.tfvars" \
    -var="subscription_id=$sub" \
    -var="tenant_id=$tenant" \
    "$@"
}

# --- Dispatch ----------------------------------------------------------------
sub="${1:-}"; shift || true
# Allow an optional `--` separator before extra terraform args.
[[ "${1:-}" == "--" ]] && shift || true

case "$sub" in
  validate) cmd_validate "$@" ;;
  plan)     cmd_plan "$@" ;;
  ""|-h|--help|help) usage ;;
  apply|destroy|import|state) die "'$sub' is not allowed locally — change state through the pipelines (infra-cd)." ;;
  *) echo "ERROR: unknown command '$sub'" >&2; usage ;;
esac
