# Outputs for the cosmos_db module.

# Built by interpolation (subscription + resource group + provider path +
# deterministic name) rather than from module.this's own resource attribute.
# The Cosmos DB account is created in the same apply as Foundry's BYOR wiring,
# which consumes this value inside a for_each condition; referencing the
# not-yet-created resource's computed ID there would make that condition
# unknown at plan time and break `terraform plan` on first apply.
output "id" {
  description = "Resource ID of the Cosmos DB account."
  value       = "${local.resource_group_id}/providers/Microsoft.DocumentDB/databaseAccounts/${local.cosmos_name}"
}

output "name" {
  description = "Name of the Cosmos DB account."
  value       = module.this.name
}

output "endpoint" {
  description = "Endpoint URI of the Cosmos DB account."
  value       = module.this.endpoint
}
