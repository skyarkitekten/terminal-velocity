output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = nonsensitive(module.this.resource.name)
}

output "workspace_id" {
  description = "Workspace ID (GUID) of the Log Analytics workspace."
  value       = nonsensitive(module.this.resource.workspace_id)
}
