---
name: terraform-azure
description: "Author and validate Terraform that provisions Azure infrastructure for this repo. Use when creating or changing resources in infra/, designing reusable modules, wiring remote state, or running the fmt/validate/plan loop before a pull request."
argument-hint: "Describe the Azure resources or module to provision."
---

# Terraform on Azure

Provision Azure infrastructure declaratively so Git fully describes the desired
state. Reusable modules are composed per environment and rolled out through
pull requests and automation.

## When to Use

- Creating or modifying Azure resources under `infra/`.
- Designing a reusable, environment-parameterized Terraform module.
- Wiring up the remote backend / state.
- Running the pre-PR validation loop (`fmt` → `validate` → `plan`).

## Procedure

1. **Model the resources.** List the Azure resources, their dependencies, and the
   identity/RBAC and networking they require. Confirm the target environment(s).
2. **Read what exists.** Inspect `infra/` and any existing modules so new code
   follows established structure and naming. Use Azure MCP/CLI to check live state
   and best practices where helpful.
3. **Author the module.** Copy `assets/module-template/` (`main.tf`,
   `variables.tf`, `outputs.tf`, `versions.tf`) and `assets/providers.tf` at the
   stack root. Pin provider versions, type and describe every variable, and mark
   secrets/outputs `sensitive`. Use Azure Verified Modules where possible, but prefer simple custom code for clarity and control in this reference implementation. Keep modules focused on a single responsibility and composable.
4. **Configure state.** Use `assets/backend.tf` with the remote `azurerm`
   backend; never commit `.tfstate`. Bootstrap the backend storage via
   `references/backend-setup.md`. Apply `assets/gitignore.snippet` and commit
   `assets/terraform.tfvars.example` (never the real `*.tfvars`).
5. **Secure by default.** No hardcoded secrets — use Key Vault and authenticate
   via OIDC / managed identity with least-privilege RBAC.
6. **Validate.** Run `scripts/validate.sh [stack_dir]` to execute the
   `fmt` → `init` → `validate` → `plan` gate (set `WITH_BACKEND=1` when state is
   reachable, `SKIP_PLAN=1` for offline checks). Surface the plan for review.
7. **Gate apply.** Never `terraform apply`/`destroy` against shared environments
   without explicit confirmation; route changes through a pull request.

See [terraform conventions](../../instructions/terraform.instructions.md) for the
full file/naming/state/security rules.

## Bundled Resources

- `scripts/validate.sh` — the pre-PR `fmt`/`init`/`validate`/`plan` loop
  (read-only; never applies). Honors `WITH_BACKEND` and `SKIP_PLAN`.
- `assets/module-template/` — reusable module stubs (`main.tf`, `variables.tf`,
  `outputs.tf`, `versions.tf`) pinned to Terraform `~> 1.9`, azurerm `~> 4.0`.
- `assets/providers.tf`, `assets/backend.tf` — stack-root provider + OIDC remote
  backend scaffolds.
- `assets/terraform.tfvars.example`, `assets/gitignore.snippet` — the tracked
  example vars and ignore rules the conventions mandate.
- `references/backend-setup.md` — one-time bootstrap of the Azure Storage state
  account, container, and RBAC.

## Output

- The Terraform files created or changed.
- `fmt`/`validate`/`plan` results.
- Next steps, flagging anything that needs confirmation before apply.
