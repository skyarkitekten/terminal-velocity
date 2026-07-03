# AI Search module.
#
# Wraps the Azure Verified Module for Azure AI Search, deriving the standard
# service name (srch-<workload>-<environment>) and wiring a private endpoint
# for the searchService sub-resource into the workload's private endpoint
# subnet.

data "azurerm_client_config" "current" {}

locals {
  name_suffix = "${var.workload}-${var.environment}"

  # Azure AI Search service names must be 2-60 characters, lowercase
  # alphanumeric or dashes, and cannot start or end with a dash. Sanitize using
  # the same replace/trim pattern as ai_foundry's avm_base local to guard
  # against invalid workload input, then truncate to the service name limit.
  sanitized_name_suffix = trim(replace(lower(local.name_suffix), "/[^a-z0-9-]/", "-"), "-")
  service_name          = substr("srch-${local.sanitized_name_suffix}", 0, 60)
  resource_group_id     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "this" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.3.0"

  name                = local.service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags

  sku             = var.sku
  replica_count   = var.replica_count
  partition_count = var.partition_count

  enable_telemetry = true

  # Public network access stays enabled so Terraform/CD pipelines, which run
  # outside the workload VNet, can continue to manage the service directly.
  # The private endpoint below adds a private connectivity path (e.g. for
  # Foundry BYOR data-plane access from inside the VNet) without removing the
  # pipeline's ability to reach the management plane.
  public_network_access_enabled = true

  # Local (API-key) authentication is left enabled by default. Foundry's
  # bring-your-own-resource (BYOR) connection to Azure AI Search is most
  # reliably established via API key at the time of writing; keyless
  # (Entra ID / RBAC-only) auth support for Foundry BYOR connections is not
  # yet consistently available. Revisit and disable local auth once Foundry
  # BYOR is confirmed to work end-to-end with keyless auth.
  local_authentication_enabled = true

  private_endpoints = {
    searchService = {
      subnet_resource_id = var.pe_subnet_id
    }
  }
}
