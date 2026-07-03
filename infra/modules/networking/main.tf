# Networking module.
#
# Provisions a virtual network and a dedicated private endpoint subnet for the
# workload environment using the Azure Verified Module for virtual networks.

data "azurerm_client_config" "current" {}

locals {
  name_suffix       = "${var.workload}-${var.environment}"
  resource_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "this" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = "vnet-${local.name_suffix}"
  location      = var.location
  parent_id     = local.resource_group_id
  address_space = var.address_space
  tags          = local.tags

  subnets = {
    private_endpoints = {
      name             = "snet-pe-${local.name_suffix}"
      address_prefixes = [var.pe_subnet_address_prefix]
      # Azure requires this disabled for a subnet to host private endpoints;
      # leaving it enabled causes private endpoint creation to fail at apply
      # time for every BYOR module wired to this subnet.
      private_endpoint_network_policies = "Disabled"
    }
  }
}
