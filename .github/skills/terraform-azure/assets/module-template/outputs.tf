# Outputs for <module_name>.
# Expose only what downstream stacks or pipelines actually consume.
# Mark any sensitive value with `sensitive = true`.

output "resource_group_id" {
  description = "Resource ID of the managed resource group."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Name of the managed resource group."
  value       = azurerm_resource_group.this.name
}
