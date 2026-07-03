output "id" {
  description = "Resource ID of the Application Insights instance."
  value       = module.this.resource_id
}

output "name" {
  description = "Name of the Application Insights instance."
  value       = module.this.name
}

output "connection_string" {
  description = "Application Insights connection string."
  value       = module.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = module.this.instrumentation_key
  sensitive   = true
}
