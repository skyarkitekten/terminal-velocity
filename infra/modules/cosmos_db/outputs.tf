# Outputs for the cosmos_db module.

output "id" {
  description = "Resource ID of the Cosmos DB account."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the Cosmos DB account."
  value       = module.this.name
}

output "endpoint" {
  description = "Endpoint URI of the Cosmos DB account."
  value       = module.this.endpoint
}
