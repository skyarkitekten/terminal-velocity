# Identity & RBAC module.
#
# Wires least-privilege, keyless RBAC for the Foundry platform:
#   - the agent runtime managed identity gets the data-plane role needed to call
#     models and use the project, and
#   - the CI deploy principal gets the role required to publish agents.
#
# Roles are referenced by definition ID (GUID) rather than name: the Foundry
# built-in roles were renamed (e.g. "Azure AI User" -> "Foundry User") and the
# IDs are stable across the rollout.

data "azurerm_role_definition" "agent_runtime" {
  role_definition_id = var.agent_runtime_role_definition_id
}

data "azurerm_role_definition" "ci_deploy" {
  role_definition_id = var.ci_deploy_role_definition_id
}

locals {
  ci_deploy_principal_id = var.ci_deploy_principal_id == null ? "" : trimspace(var.ci_deploy_principal_id)
  ci_deploy_enabled      = local.ci_deploy_principal_id != ""
}

# Agent runtime identity -> Foundry User on the Foundry account (data-plane:
# call models, use the project at runtime).
resource "azurerm_role_assignment" "agent_runtime" {
  scope              = var.foundry_account_id
  role_definition_id = data.azurerm_role_definition.agent_runtime.id
  principal_id       = var.agent_runtime_principal_id
  principal_type     = "ServicePrincipal"
}

# CI deploy principal -> Foundry Project Manager on the Foundry account (publish
# agents). Conditional so plan/apply works before the principal id is wired in.
resource "azurerm_role_assignment" "ci_deploy" {
  count = local.ci_deploy_enabled ? 1 : 0

  scope              = var.foundry_account_id
  role_definition_id = data.azurerm_role_definition.ci_deploy.id
  principal_id       = local.ci_deploy_principal_id
  principal_type     = "ServicePrincipal"
}
