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
  version = "0.11.2"

  base_name                  = local.avm_base
  location                   = var.location
  resource_group_resource_id = var.resource_group_id
  enable_telemetry           = var.enable_telemetry
  tags                       = local.tags

  # BYOR: link the Foundry account/project to our own Key Vault, Storage
  # Account, Cosmos DB, and AI Search rather than letting the module create
  # (and own the lifecycle of) those dependent data services.
  create_byor = true

  # Only the Foundry account itself gets a module-owned private endpoint here.
  # The BYOR dependencies (Key Vault, Storage, Cosmos DB, AI Search) already
  # provision their own private endpoints in their respective modules.
  create_private_endpoints            = true
  private_endpoint_subnet_resource_id = var.pe_subnet_id

  # Public network access stays enabled even with the private endpoint in
  # place: our GitHub Actions OIDC runners have no VNet line-of-sight, so
  # making the Foundry account private-only would break CI/CD applies. The
  # private endpoint is additive, matching the BYOR dependency modules.
  ai_foundry = {
    name                          = "aif-${local.name_suffix}"
    sku                           = "S0"
    disable_local_auth            = true
    allow_project_management      = true
    create_ai_agent_service       = false
    public_network_access_enabled = true
  }

  key_vault_definition = {
    default = {
      existing_resource_id = var.key_vault_id
    }
  }

  storage_account_definition = {
    default = {
      existing_resource_id = var.storage_account_id
    }
  }

  cosmosdb_definition = {
    default = {
      existing_resource_id = var.cosmosdb_id
    }
  }

  ai_search_definition = {
    default = {
      existing_resource_id = var.ai_search_id
    }
  }

  diagnostic_settings = {
    to_law = {
      name                           = "diag-to-law"
      workspace_resource_id          = var.log_analytics_workspace_id
      log_analytics_destination_type = "Dedicated"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
    }
  }

  ai_model_deployments = var.model_deployments

  ai_projects = {
    default = {
      name         = "aifp-${local.name_suffix}"
      display_name = "Terminal Velocity - ${var.environment}"
      description  = "Foundry project for Terminal Velocity agents (${var.environment})"

      create_project_connections = true
      # True BYOR: these resources are created by our own modules, not by
      # this pattern module, so the project connections reference them via
      # existing_resource_id (matching the *_definition maps above) rather
      # than new_resource_map_key, which only resolves when the pattern
      # module itself creates the dependent resource.
      key_vault_connection = {
        existing_resource_id = var.key_vault_id
      }
      storage_account_connection = {
        existing_resource_id = var.storage_account_id
      }
      cosmos_db_connection = {
        existing_resource_id = var.cosmosdb_id
      }
      ai_search_connection = {
        existing_resource_id = var.ai_search_id
      }
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
