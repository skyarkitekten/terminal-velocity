# Create the Infrastructure

- model the resources
- create the terraform files
- use infra agent and supporting skills

## 0. Agentic SDLC

### Platform Engineer Agent

The platform engineer agent is your copilot for infrastructure as code. It can help you model Azure resources, author Terraform modules, configure remote state, and validate changes before deployment. Use it to scaffold new modules, generate boilerplate code, and get guidance on best practices.

### Skills

- **terraform-azure**: Generates Terraform code for Azure resources based on your descriptions and requirements.
- **gitops-delivery**: Manages the CI/CD pipeline for your infrastructure code, including validation and deployment workflows.

### Instructions

- `terraform.instructions.md`: Conventions and best practices for authoring Terraform code in this repo, including file structure, naming, state management, and security guidelines.

### Prompts

Try it with prompts like:

- "Use the terraform-azure skill to scaffold a module for an Azure Container Apps environment under infra."

- "Bootstrap the remote state backend for this repo."

- "Run the terraform validation gate on infra/dev."

## 1. Bootstrap the Remote State Backend

Terraform needs a place to store state before any stack can run. The `azurerm`
backend requires an Azure Storage account and container to **already exist** —
this is a one-time, per-subscription bootstrap that isn't managed by the stacks
that consume it (a deliberate chicken-and-egg break). Run it once, then every
stack reuses the backend via a unique `key`.

### Set your context

Confirm who you are and where you're deploying. Export these once so the rest of
the commands are copy-pasteable and portable:

```bash
# Sign in (opens a browser). Add --tenant <id> to target a specific tenant.
az login

# Pick the subscription that will hold the state backend.
az account list --query "[].{name:name, id:id}" -o table
az account set --subscription "<subscription-id>"

# Export the bootstrap parameters. Adjust names/region to your conventions.
export LOCATION="<azure-region>"           # e.g. the region closest to your team
export RG_STATE="<state-resource-group>"   # e.g. rg-tfstate
export SA_STATE="<unique-storage-account>" # 3-24 lowercase alphanumerics, globally unique
export CONTAINER="tfstate"
```

> Tip: storage account names must be globally unique. A quick way to get one is
> `export SA_STATE="sttfstate$RANDOM"`. Some subscriptions enforce governance
> policies (required tags, allowed regions, naming) — add whatever your
> subscription requires to the `create` commands below.

### Create the backend resources

```bash
# Resource group to hold the state account.
az group create --name "$RG_STATE" --location "$LOCATION"

# Storage account: locked down, TLS 1.2+, no public blob access.
az storage account create \
  --name "$SA_STATE" \
  --resource-group "$RG_STATE" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Enable blob versioning + soft delete so a bad apply is recoverable.
az storage account blob-service-properties update \
  --account-name "$SA_STATE" \
  --resource-group "$RG_STATE" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30
```

### Grant data-plane access (keyless)

Prefer Entra (Azure AD) auth over account keys. Grant the identity that will
read/write state **Storage Blob Data Contributor** on the account:

```bash
# Scope to the storage account.
export SA_ID="$(az storage account show \
  --name "$SA_STATE" --resource-group "$RG_STATE" --query id -o tsv)"

# Grant your own user (for local runs). For CI, assign the same role to the
# OIDC/managed identity's principal instead.
export USER_OID="$(az ad signed-in-user show --query id -o tsv)"
az role assignment create \
  --assignee-object-id "$USER_OID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID"
```

### Create the state container

Use Entra auth (no account keys). RBAC can take a moment to propagate, so retry
if the first attempt is denied:

```bash
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_STATE" \
  --auth-mode login
```

### Wire it to your stacks

Keep `backend.tf` value-free and pass the coordinates at init time, so the same
code initializes against any environment:

```bash
terraform init \
  -backend-config="resource_group_name=$RG_STATE" \
  -backend-config="storage_account_name=$SA_STATE" \
  -backend-config="container_name=$CONTAINER" \
  -backend-config="key=<env>/<stack>.tfstate"
```

Use a unique `key` per environment + stack (e.g. `dev/network.tfstate`). In CI,
authenticate with OIDC (`use_oidc = true`, `ARM_CLIENT_ID` / `ARM_TENANT_ID` /
`ARM_SUBSCRIPTION_ID`) — never client secrets or storage keys.

> State contains secrets in plaintext. Lock down RBAC, keep the account private,
> and rely on encryption at rest (default). Never commit `*.tfstate`.

## 2. Create the CICD pipeline

With the backend in place, wire Git to Azure so that pull requests plan and
merges deploy — keyless, auditable, and promoted dev → prod through Git.

### Workflows

Three workflows under `.github/workflows/` implement a standard GitOps loop:

| Workflow        | Trigger                    | Responsibility                                                                                                                                     |
| --------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `terraform.yml` | `workflow_call` (reusable) | `fmt` → `init` → `validate` → `plan`, and a conditional `apply`. Runs in a GitHub Environment so its variables, secrets, and approval gates apply. |
| `infra-ci.yml`  | PR touching `infra/**`     | Plan-only against **dev**. The plan is the review artifact — it never applies.                                                                     |
| `infra-cd.yml`  | Push to `main` / manual    | `deploy-dev` (apply) → `deploy-prod` (apply). `deploy-prod` `needs` dev and runs only after the prod environment's reviewer approves.              |

Everything authenticates with **OIDC** — `azure/login` exchanges the workflow's
short-lived token for Azure credentials, and the `azurerm` backend reuses it
(`ARM_USE_OIDC=true`). No client secrets or storage keys are ever stored.

The reusable workflow is environment-parameterized, so the same code serves dev
and prod; only the `environment` input (and its scoped variables/secrets)
changes. The backend `key` is derived per environment
(`<env>/terminal-velocity.tfstate`), and an optional
`infra/environments/<env>.tfvars` is applied when present.

### Two environments: variables and secrets

Each GitHub Environment (`dev`, `prod`) supplies its own configuration, so the
same workflow targets different subscriptions/settings without code changes:

- **Variables** (non-secret IDs the workflow reads): `AZURE_CLIENT_ID`,
  `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TFSTATE_RESOURCE_GROUP`,
  `TFSTATE_STORAGE_ACCOUNT`, `TFSTATE_CONTAINER`.
- **Secrets** (e.g. a DB admin password): set on the environment, then surfaced
  to Terraform by mapping them to `TF_VAR_*` in the `env:` block of
  `terraform.yml`.

### Approval gate (dev → prod)

The prod environment carries a **required reviewer**. Because `deploy-prod`
declares `environment: prod`, GitHub pauses that job until an approver signs off
— a manual gate between the automatic dev apply and the prod apply.

### Bootstrap the trust (one-time, per repo)

The OIDC trust and GitHub Environment configuration are themselves bootstrap
(like the state backend). Run the idempotent, portable helper — it resolves the
repo, subscription, and tenant from your current `gh`/`az` context and accepts
overrides via environment variables:

```bash
# Preview everything without making changes.
DRY_RUN=true ./infra/scripts/bootstrap-cicd-oidc.sh

# Apply: create the Entra app + SP, add per-environment federated credentials,
# grant RBAC, and create the dev/prod environments with prod requiring a review.
./infra/scripts/bootstrap-cicd-oidc.sh

# Customize for another repo / reviewer / state account, e.g.:
REPO="org/other-repo" PROD_REVIEWER="octocat" \
  TFSTATE_STORAGE_ACCOUNT="sttfstateXXXXX" \
  ./infra/scripts/bootstrap-cicd-oidc.sh
```

The script sets the per-environment **variables** but never secrets — add any
environment secrets your stack needs afterward, and map them to `TF_VAR_*` in
`terraform.yml`.

> Re-running is safe: existing apps, credentials, role assignments, and
> environments are detected and left in place.

## Options

- Suggested next customization: a companion gitops-delivery enhancement — a
  reusable workflow that posts the `terraform plan` output as a sticky PR comment
  so reviewers see the diff inline before approving the promotion to prod.
