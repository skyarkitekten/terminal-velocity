# Outputs for the platform stack — re-exposed from composed modules.

output "resource_group_name" {
  description = "Name of the stack's resource group."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource ID of the stack's resource group."
  value       = module.resource_group.id
}

output "location" {
  description = "Azure region the stack is deployed to."
  value       = module.resource_group.location
}
