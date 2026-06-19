# Outputs for the resource_group module.

output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "Azure region the resource group is deployed to."
  value       = azurerm_resource_group.this.location
}
