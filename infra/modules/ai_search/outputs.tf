# Outputs for the ai_search module.

output "id" {
  description = "Resource ID of the Azure AI Search service."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the Azure AI Search service."
  value       = module.this.resource.name
}
