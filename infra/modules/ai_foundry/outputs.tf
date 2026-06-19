output "foundry_id" {
  description = "Azure AI Foundry account resource ID."
  value       = module.foundry.ai_foundry_id
}

output "foundry_name" {
  description = "Azure AI Foundry account name."
  value       = module.foundry.ai_foundry_name
}

output "project_id" {
  description = "Default Foundry project resource ID."
  value       = module.foundry.ai_foundry_project_id["default"]
}

output "project_name" {
  description = "Default Foundry project name."
  value       = module.foundry.ai_foundry_project_name["default"]
}

output "openai_endpoint" {
  description = "OpenAI-compatible endpoint for model SDK clients."
  value       = "https://${module.foundry.ai_foundry_name}.cognitiveservices.azure.com/"
}
