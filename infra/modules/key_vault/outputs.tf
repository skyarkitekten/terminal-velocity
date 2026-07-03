# Outputs for the key_vault module.

output "id" {
  description = "Resource ID of the Key Vault."
  value       = module.this.resource_id
}

output "resource_id" {
  description = "Resource ID of the Key Vault."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the Key Vault."
  value       = module.this.name
}

output "uri" {
  description = "Vault URI for data-plane operations."
  value       = module.this.uri
}
