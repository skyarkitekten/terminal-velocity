# Outputs for the resource_group module.

output "name" {
  description = "Name of the resource group."
  value       = module.this.name
}

output "id" {
  description = "Resource ID of the resource group."
  value       = module.this.resource_id
}

output "location" {
  description = "Azure region the resource group is deployed to."
  value       = module.this.location
}
