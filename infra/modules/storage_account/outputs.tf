# Outputs for the storage_account module.

output "id" {
  description = "Resource ID of the storage account."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the storage account."
  value       = module.this.name
}
