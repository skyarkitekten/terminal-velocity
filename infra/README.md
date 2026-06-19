# `infra/`

Declarative Azure infrastructure for Terminal Velocity. Git is the source of
truth; changes flow through pull requests and are rolled out by GitHub Actions
using OIDC (no long-lived secrets).

## Layout

```
infra/
  scripts/                  Operational scripts (CI/CD OIDC bootstrap, region check)
  modules/                  Reusable, environment-agnostic building blocks
    resource_group/         Derives rg name + policy tags from inputs
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

Run the pre-PR gate from the stack directory (read-only — never applies):

```sh
cd infra/stacks/platform
terraform fmt -recursive ../..        # format the whole infra tree
terraform init -backend=false         # offline init (no state access)
terraform validate
```

Add `-var-file=environments/dev.tfvars` to a `plan` when backend state is
reachable.
