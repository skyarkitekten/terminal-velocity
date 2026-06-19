# AI Foundry module.
#
# Wraps the Azure Verified Module pattern for AI Foundry, adding the App Insights
# connection and soft-delete purge handling required by the Foundry lifecycle.

locals {
  name_suffix = "${var.workload}-${var.environment}"

  # AVM base_name must be 3-9 lowercase alphanumeric characters.
  avm_base_raw = trim(replace(lower(var.workload), "/[^a-z0-9-]/", "-"), "-")
  avm_base     = length(trim(substr(local.avm_base_raw, 0, 9), "-")) >= 3 ? trim(substr(local.avm_base_raw, 0, 9), "-") : "tvelo"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "foundry" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "~> 0.10"

  base_name                  = local.avm_base
  location                   = var.location
  resource_group_resource_id = var.resource_group_id
  enable_telemetry           = var.enable_telemetry
  tags                       = local.tags

  create_byor              = false
  create_private_endpoints = false

  diagnostic_settings = {
    to_law = {
      name                           = "diag-to-law"
      workspace_resource_id          = var.log_analytics_workspace_id
      log_analytics_destination_type = "Dedicated"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
    }
  }

  ai_foundry = {
    name                     = "aif-${local.name_suffix}"
    sku                      = "S0"
    disable_local_auth       = true
    allow_project_management = true
    create_ai_agent_service  = false
  }

  ai_model_deployments = var.model_deployments

  ai_projects = {
    default = {
      name         = "aifp-${local.name_suffix}"
      display_name = "Terminal Velocity - ${var.environment}"
      description  = "Foundry project for Terminal Velocity agents (${var.environment})"
    }
  }

  depends_on = [time_sleep.wait_before_purge_foundry]
}

# Wire Application Insights into the Foundry account as a connection.
resource "azapi_resource" "appinsights_connection" {
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name                      = var.application_insights_name
  parent_id                 = module.foundry.ai_foundry_id
  schema_validation_enabled = false

  body = {
    name = var.application_insights_name
    properties = {
      category      = "AppInsights"
      target        = var.application_insights_id
      authType      = "ApiKey"
      isSharedToAll = true

      credentials = {
        key = var.application_insights_connection_string
      }

      metadata = {
        ApiType    = "Azure"
        ResourceId = var.application_insights_id
      }
    }
  }

  depends_on = [module.foundry]
}

# Purge any soft-deleted Foundry account with the same name before recreating.
resource "azapi_resource_action" "purge_ai_foundry" {
  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/resourceGroups/${var.resource_group_name}/deletedAccounts/aif-${local.name_suffix}"
  type        = "Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts@2025-06-01"
  when        = "destroy"
}

resource "time_sleep" "wait_before_purge_foundry" {
  destroy_duration = "60s"
  depends_on       = [azapi_resource_action.purge_ai_foundry]
}

data "azurerm_client_config" "current" {}
