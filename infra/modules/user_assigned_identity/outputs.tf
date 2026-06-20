# Outputs for the user_assigned_identity module.

output "id" {
  description = "Resource ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Principal (object) ID of the managed identity, used for RBAC role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID of the managed identity, consumed by the agent runtime / delivery pipeline."
  value       = azurerm_user_assigned_identity.this.client_id
}
