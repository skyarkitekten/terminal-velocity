# Outputs for the platform stack — re-exposed from composed modules.

output "resource_group_name" {
  description = "Name of the stack's resource group."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource ID of the stack's resource group."
  value       = module.resource_group.id
}

output "location" {
  description = "Azure region the stack is deployed to."
  value       = module.resource_group.location
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace receiving platform diagnostics."
  value       = module.log_analytics.name
}

output "application_insights_name" {
  description = "Application Insights instance for agent telemetry."
  value       = module.application_insights.name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string for agent SDK configuration."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "ai_foundry_id" {
  description = "Azure AI Foundry account resource ID."
  value       = module.ai_foundry.foundry_id
}

output "ai_foundry_name" {
  description = "Azure AI Foundry account name."
  value       = module.ai_foundry.foundry_name
}

output "ai_foundry_project_id" {
  description = "Default Foundry project resource ID."
  value       = module.ai_foundry.project_id
}

output "ai_foundry_project_name" {
  description = "Default Foundry project name."
  value       = module.ai_foundry.project_name
}

output "openai_endpoint" {
  description = "OpenAI-compatible endpoint for model SDK clients."
  value       = module.ai_foundry.openai_endpoint
}
