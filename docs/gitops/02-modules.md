# Modules — AI Foundry Platform

This guide covers the Terraform modules that provision Microsoft Foundry for
agent deployment. It explains how to provide backend configuration in CI, run
`terraform plan` to verify your changes, and commit safely.

## Architecture Overview

The platform stack (`infra/stacks/platform`) composes four modules:

| Module | Purpose |
|--------|---------|
| `resource_group` | Shared resource group for all platform resources |
| `log_analytics` | Log Analytics workspace — central diagnostics sink |
| `application_insights` | Workspace-backed App Insights for agent telemetry |
| `ai_foundry` | AI Foundry account, project, model deployment, and observability wiring |

```
Resource Group
├── Log Analytics Workspace
├── Application Insights ──────► Log Analytics
└── AI Foundry Account (S0)
    ├── Foundry Project ("Terminal Velocity - <env>")
    ├── Model Deployment (gpt-4.1-mini, GlobalStandard)
    ├── App Insights Connection
    └── Diagnostic Settings ──► Log Analytics
```

The `ai_foundry` module wraps the Azure Verified Module
[`Azure/avm-ptn-aiml-ai-foundry/azurerm`](https://registry.terraform.io/modules/Azure/avm-ptn-aiml-ai-foundry/azurerm/latest)
and adds the Application Insights connection (via `azapi`) and soft-delete purge
handling required by the Foundry lifecycle.

## Provide Backend Config in CI

The `backend.tf` in the platform stack is value-free — coordinates are passed at
`terraform init` time so nothing environment-specific is committed. In your CI
workflow (or locally), supply them via `-backend-config` flags:

```bash
terraform -chdir=infra/stacks/platform init \
  -backend-config="resource_group_name=$TFSTATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="container_name=$TFSTATE_CONTAINER" \
  -backend-config="key=${ENVIRONMENT}/terminal-velocity.tfstate"
```

In GitHub Actions these values come from **environment variables** set on the
`dev` and `prod` GitHub Environments:

| Variable | Description |
|----------|-------------|
| `AZURE_CLIENT_ID` | App registration / managed identity client ID (OIDC) |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `TFSTATE_RESOURCE_GROUP` | Resource group holding the state storage account |
| `TFSTATE_STORAGE_ACCOUNT` | Storage account name (globally unique) |
| `TFSTATE_CONTAINER` | Blob container name (e.g. `tfstate`) |

Authentication is keyless — the workflow exchanges its OIDC token via
`azure/login` and the `azurerm` backend reuses it (`use_oidc = true`,
`use_azuread_auth = true`).

## Run Terraform Plan to Verify

After initializing the backend, run a plan against the target environment to
verify the modules will deploy correctly:

```bash
# Format check (must pass before plan)
terraform -chdir=infra/stacks/platform fmt -check

# Validate syntax and module references
terraform -chdir=infra/stacks/platform validate

# Plan against the dev environment
terraform -chdir=infra/stacks/platform plan \
  -var-file=environments/dev.tfvars \
  -out=tfplan.binary
```

Review the plan output. You should see:

- 1 Log Analytics workspace (`law-terminal-velocity-dev`)
- 1 Application Insights instance (`appi-terminal-velocity-dev`)
- 1 AI Foundry account (`aif-terminal-velocity-dev`)
- 1 Foundry project (`aifp-terminal-velocity-dev`)
- 1 model deployment (`gpt-4.1-mini`)
- 1 App Insights connection
- Supporting resources from the AVM module (Key Vault, Storage Account)

If the plan is clean, you're ready to commit.

> **Tip**: In CI, the `infra-ci.yml` workflow runs this plan automatically on
> PRs touching `infra/**` and posts the output for review. It never applies.

## Commit Changes

Follow the standard GitOps flow — changes to `infra/` trigger the CI/CD
pipeline:

```bash
# Stage your module changes
git add infra/

# Commit with a conventional commit message
git commit -m "feat(infra): add AI Foundry modules for agent deployment"

# Push and open a PR
git push origin HEAD
gh pr create --title "Add AI Foundry Terraform modules" --fill
```

The PR triggers `infra-ci.yml` which runs `fmt` → `init` → `validate` → `plan`
against dev. Reviewers see the plan diff inline. Once merged to `main`,
`infra-cd.yml` applies to dev automatically, then waits for prod approval.

## Customizing Model Deployments

Override the default model deployment via `model_deployments` in your `.tfvars`:

```hcl
model_deployments = {
  "gpt-4.1-mini" = {
    name = "gpt-4.1-mini"
    model = {
      format  = "OpenAI"
      name    = "gpt-4.1-mini"
      version = "2025-04-14"
    }
    scale = {
      type     = "GlobalStandard"
      capacity = 10
    }
  }
  "gpt-4.1" = {
    name = "gpt-4.1"
    model = {
      format  = "OpenAI"
      name    = "gpt-4.1"
      version = "2025-04-14"
    }
    scale = {
      type     = "GlobalStandard"
      capacity = 5
    }
  }
}
```

## Security Notes

- **Local auth disabled** — all access to the Foundry account requires Entra ID
  (no API keys).
- **No private endpoints yet** — the walking skeleton uses public access. Layer
  private networking by setting `create_private_endpoints = true` in the
  `ai_foundry` module when ready.
- **Diagnostics from day one** — all logs and metrics flow to Log Analytics for
  auditability.
- **Soft-delete purge** — the module handles Cognitive Services soft-delete to
  avoid naming conflicts on destroy/recreate cycles.
