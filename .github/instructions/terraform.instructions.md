---
description: "Conventions for authoring Terraform that provisions Azure infrastructure in this repo. Applies to all .tf files."
applyTo: "**/*.tf"
---

# Terraform Conventions

Terraform is the declarative source of truth for infrastructure in `infra/`.
Every change must be auditable, reviewable in a pull request, and applied through
automation — never click-ops.

## Layout & Naming
- Keep environment-agnostic, reusable code in modules; compose them per
  environment. Don't copy-paste resource blocks between environments.
- Standard files per module/stack: `main.tf`, `variables.tf`, `outputs.tf`,
  `versions.tf` (and `providers.tf` only at the root/stack level).
- Resource and variable names use `snake_case`. Azure resource *names* follow the
  workload's documented naming scheme; derive them from variables, never hardcode.
- One logical concern per file; split large `main.tf` by resource group/domain.

## Providers & Versions
- Pin the `azurerm` (and any other) provider with a `~>` constraint and set
  `required_version` for Terraform itself in `versions.tf`.
- Configure `azurerm` with `features {}`; prefer `subscription_id`/`tenant_id`
  sourced from variables or the environment, not literals.

## State
- Use a remote backend (Azure Storage `azurerm` backend) — never commit local
  state or `.tfstate` files. Ensure state is locked and access-controlled.
- Add `*.tfstate*`, `.terraform/`, and `*.tfvars` containing secrets to
  `.gitignore`. Commit `*.tfvars.example` instead.

## Variables & Outputs
- Every variable has a `type` and a `description`; provide `default` only when a
  sane one exists. Add `validation` blocks for constrained inputs.
- Mark secret inputs and any sensitive outputs with `sensitive = true`.
- Outputs expose only what downstream stacks or pipelines actually consume.

## Security
- No secrets, connection strings, or credentials in `.tf` or `.tfvars`. Use Key
  Vault references, and authenticate pipelines via OIDC / managed identity.
- Grant least-privilege RBAC; prefer managed identities over service principals
  with client secrets.

## Quality Gates
- Code must pass `terraform fmt`, `terraform validate`, and produce a clean
  `terraform plan` before review. Surface the plan in the PR.
- Keep changes minimal and composable — add only what the request requires.
