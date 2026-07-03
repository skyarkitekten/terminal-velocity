# Outputs for the storage_account module.

# Built by interpolation rather than module.this's own resource attribute -
# see the comment on local.name_hash in main.tf for why.
output "id" {
  description = "Resource ID of the storage account."
  value       = "${local.resource_group_id}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
}

output "name" {
  description = "Name of the storage account."
  value       = module.this.name
}
