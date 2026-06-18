output "id" {
  description = "Resource ID of the Application Insights instance."
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Name of the Application Insights instance."
  value       = azurerm_application_insights.this.name
}

output "connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
