# Outputs for the key_vault module.

# Built by interpolation (subscription + resource group + provider path +
# deterministic name) rather than from module.this's own resource attribute.
# The Key Vault is created in the same apply as Foundry's BYOR wiring, which
# consumes this value inside a for_each condition; referencing the not-yet-
# created resource's computed ID there would make that condition unknown at
# plan time and break `terraform plan` on first apply.
output "id" {
  description = "Resource ID of the Key Vault."
  value       = "${var.resource_group_id}/providers/Microsoft.KeyVault/vaults/${local.kv_name}"
}

output "resource_id" {
  description = "Resource ID of the Key Vault."
  value       = "${var.resource_group_id}/providers/Microsoft.KeyVault/vaults/${local.kv_name}"
}

output "name" {
  description = "Name of the Key Vault."
  value       = module.this.name
}

output "uri" {
  description = "Vault URI for data-plane operations."
  value       = module.this.uri
}
