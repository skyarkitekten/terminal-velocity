# Cosmos DB module.
#
# Provisions a minimal Azure Cosmos DB account (NoSQL API) for Azure AI Foundry
# BYOR scenarios and adds a private endpoint on the shared private endpoint
# subnet. Public network access remains enabled so the GitHub Actions OIDC CD
# pipeline can keep managing the resource over the control plane while runtime
# traffic can use the private endpoint.

locals {
  workload_fragment_raw = trim(replace(lower(var.workload), "/[^a-z0-9-]/", "-"), "-")
  max_workload_length   = 44 - length("cosmos--${var.environment}")
  workload_fragment     = length(trim(substr(local.workload_fragment_raw, 0, local.max_workload_length), "-")) > 0 ? trim(substr(local.workload_fragment_raw, 0, local.max_workload_length), "-") : "app"
  cosmos_name           = "cosmos-${local.workload_fragment}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "this" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.10.0"

  name                = local.cosmos_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  enable_telemetry              = true
  free_tier_enabled             = var.free_tier_enabled
  automatic_failover_enabled    = false
  public_network_access_enabled = true

  consistency_policy = {
    consistency_level = var.consistency_level
  }

  geo_locations = [
    {
      location          = var.location
      failover_priority = 0
      zone_redundant    = false
    }
  ]

  capabilities = [
    {
      name = "EnableServerless"
    }
  ]

  private_endpoints_manage_dns_zone_group = false

  private_endpoints = {
    sql = {
      name                            = "pe-${local.cosmos_name}"
      network_interface_name          = "nic-${local.cosmos_name}"
      private_service_connection_name = "psc-${local.cosmos_name}"
      subnet_resource_id              = var.pe_subnet_id
      subresource_name                = "SQL"
      tags                            = local.tags
    }
  }
}
