# Outputs for the Terminal Velocity root stack.

output "resource_group_name" {
  description = "Name of the stack's resource group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource ID of the stack's resource group."
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region the stack is deployed to."
  value       = azurerm_resource_group.main.location
}
