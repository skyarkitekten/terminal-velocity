# Outputs for the ai_search module.

# Built by interpolation rather than module.this's own resource attribute -
# see the comment on local.resource_group_id in main.tf for why.
output "id" {
  description = "Resource ID of the Azure AI Search service."
  value       = "${local.resource_group_id}/providers/Microsoft.Search/searchServices/${local.service_name}"
}

output "name" {
  description = "Name of the Azure AI Search service."
  value       = module.this.resource.name
}
