# Outputs for the identity_rbac module.

output "agent_runtime_role_assignment_id" {
  description = "Resource ID of the agent runtime role assignment."
  value       = azurerm_role_assignment.agent_runtime.id
}

output "ci_deploy_role_assignment_id" {
  description = "Resource ID of the CI deploy role assignment, or null when not configured."
  value       = one(azurerm_role_assignment.ci_deploy[*].id)
}
