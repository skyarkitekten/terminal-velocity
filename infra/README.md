# `infra/`

Declarative Azure infrastructure for Terminal Velocity. Git is the source of
truth; changes flow through pull requests and are rolled out by GitHub Actions
using OIDC (no long-lived secrets).

## Layout

```
infra/
  scripts/                  Operational scripts (CI/CD OIDC bootstrap, region check, local validate/plan)
  modules/                  Reusable, environment-agnostic building blocks
    resource_group/         Resource group (AVM avm-res-resources-resourcegroup)
    log_analytics/          Log Analytics workspace (AVM avm-res-operationalinsights-workspace)
    application_insights/   Workspace-backed App Insights (AVM avm-res-insights-component)
    user_assigned_identity/ Agent runtime managed identity (AVM avm-res-managedidentity-userassignedidentity)
    networking/             VNet + private-endpoint subnet, one per environment (AVM avm-res-network-virtualnetwork)
    key_vault/              BYOR Key Vault + private endpoint (AVM avm-res-keyvault-vault)
    storage_account/        BYOR Storage Account + private endpoint (AVM avm-res-storage-storageaccount)
    cosmos_db/              BYOR Cosmos DB account + private endpoint (AVM avm-res-documentdb-databaseaccount)
    ai_search/              BYOR AI Search service + private endpoint (AVM avm-res-search-searchservice)
    ai_foundry/             Foundry account + project + model deployments, BYOR-wired (AVM avm-ptn-aiml-ai-foundry)
    identity_rbac/          Least-privilege Foundry role assignments (no AVM equivalent; hand-rolled)
  stacks/                   Deployable composition roots (provider + backend live here)
    platform/               The stack CI plans/applies
      main.tf               Composes modules — no raw resources
      providers.tf          azurerm provider (root-only)
      backend.tf            azurerm remote state, OIDC (root-only)
      variables.tf          Stack inputs
      outputs.tf            Re-exposed from module outputs
      versions.tf           Terraform + provider version pins
      environments/         Per-environment inputs
        dev.tfvars
        prod.tfvars
```

- **`modules/`** = _what_ to build (reusable, no provider/backend). New building
  blocks go here.
- **`stacks/`** = _where it runs_ (provider, backend, environment inputs). Wire
  modules together here.

## Azure Verified Modules (AVM)

Every module wraps an [Azure Verified Module](https://azure.github.io/Azure-Verified-Modules/)
instead of hand-rolled `azurerm_*` resources, except `identity_rbac`
(a single `azurerm_role_assignment` — no AVM module exists for that). AVM
absorbs the churn of fast-moving services (this is why `ai_foundry` tracks
Foundry's pattern module rather than reimplementing it) and gives us
consistent RBAC, diagnostic-settings, and private-endpoint interfaces across
every resource type.

**Versioning policy: pin every AVM module to an exact version** (no `~>`
ranges on the `version =` of an AVM `source =`). AVM modules — especially
`avm-ptn-aiml-ai-foundry` — have shipped breaking changes within a single
minor version bump (e.g. BYOR becoming mandatory for production in `0.11.0`).
An unpinned range can silently change the plan on the next `terraform init`.
Bump versions deliberately, in their own PR, after reading the changelog.

| Module | AVM source | Version |
|---|---|---|
| `resource_group` | `Azure/avm-res-resources-resourcegroup/azurerm` | `0.4.0` |
| `log_analytics` | `Azure/avm-res-operationalinsights-workspace/azurerm` | `0.5.1` |
| `application_insights` | `Azure/avm-res-insights-component/azurerm` | `0.4.0` |
| `user_assigned_identity` | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | `0.5.0` |
| `networking` | `Azure/avm-res-network-virtualnetwork/azurerm` | `0.19.0` |
| `key_vault` | `Azure/avm-res-keyvault-vault/azurerm` | `0.10.2` |
| `storage_account` | `Azure/avm-res-storage-storageaccount/azurerm` | `0.7.2` |
| `cosmos_db` | `Azure/avm-res-documentdb-databaseaccount/azurerm` | `0.10.0` |
| `ai_search` | `Azure/avm-res-search-searchservice/azurerm` | `0.3.0` |
| `ai_foundry` | `Azure/avm-ptn-aiml-ai-foundry/azurerm` | `0.11.2` |

Provider version constraints (`azurerm`, `azapi`, etc.) still use `~>` ranges
as usual — only the AVM module `version` is pinned exactly.

## BYOR and private networking

`ai_foundry`'s AVM pattern module requires BYOR (Bring Your Own Resource) for
production as of `0.11.0`: the Foundry account no longer creates its own Key
Vault, Storage Account, Cosmos DB, or AI Search — it links to resources we
provide. This repo runs BYOR in both `dev` and `prod` so environments stay
symmetric.

- `networking` provisions one VNet and one private-endpoint subnet per
  environment (simple topology — no hub-spoke, no on-prem connectivity).
- `key_vault`, `storage_account`, `cosmos_db`, and `ai_search` each own their
  resource's full lifecycle and provision a private endpoint into that
  subnet.
- `ai_foundry` links to those four resources via `existing_resource_id` and
  gets its own private endpoint too (`create_private_endpoints = true`).
- **Public network access stays enabled** on all of the above, including the
  Foundry account itself, even with private endpoints in place. GitHub
  Actions OIDC runners have no VNet line-of-sight, so a private-only resource
  would break `terraform plan`/`apply` from CI. Private endpoints are
  additive hardening, not the sole access path, until the CD pipeline runs
  from inside the VNet (e.g. via a self-hosted runner).

## CI contract

The reusable [`terraform.yml`](../.github/workflows/terraform.yml) workflow runs
from `infra/stacks/platform`:

- **State** — `azurerm` backend, keyless via OIDC. Coordinates are passed at
  `init` time (`-backend-config=...`); the state `key` is
  `<environment>/terminal-velocity.tfstate`. Nothing environment-specific is
  committed.
- **Inputs** — `terraform.yml` resolves `environments/<environment>.tfvars`.
  Subscription/tenant come from Actions _variables_ via `TF_VAR_*`/`ARM_*`.
- **Promotion** — [`infra-ci.yml`](../.github/workflows/infra-ci.yml) plans on PRs
  (never applies); [`infra-cd.yml`](../.github/workflows/infra-cd.yml) applies to
  `dev` then `prod` (prod gated by required reviewers) on merge to `main`.

## Local validation

Use the repo's read-only helper (never applies):

```sh
./infra/scripts/tf-local.sh validate       # fmt + offline validate, no creds needed
./infra/scripts/tf-local.sh plan dev       # read-only plan against real dev state (az login required)
./infra/scripts/tf-local.sh plan prod      # same, against prod state
```

`validate` needs nothing but `terraform`. `plan` needs `az login` to the
correct tenant/subscription and `gh` (to read backend coordinates from
Actions variables), and never writes a plan file that could be applied.

