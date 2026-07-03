# Storage account module.
#
# Wraps the AVM storage account module for Azure AI Foundry BYOR usage. Storage
# account names must be globally unique and limited to 3-24 lowercase
# alphanumeric characters, so this module sanitizes/truncates the
# workload/environment prefix and appends a stable hash suffix derived from the
# resource group/workload/environment (deterministic, not a random resource, so
# the name - and its resource ID - are known at plan time on first apply).
#
# Public network access stays enabled on purpose: the GitHub Actions OIDC-based
# delivery pipeline manages this resource over Azure's management plane without
# VNet line of sight. The blob private endpoint is added as an additional access
# path for BYOR consumers rather than making private connectivity the sole path.

data "azurerm_client_config" "current" {}

locals {
  name_suffix       = "${var.workload}-${var.environment}"
  resource_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  workload_name_raw    = join("", regexall("[a-z0-9]", lower(var.workload)))
  environment_name_raw = join("", regexall("[a-z0-9]", lower(var.environment)))
  environment_name     = length(local.environment_name_raw) > 0 ? local.environment_name_raw : "dev"

  # Deterministic hash suffix (rather than a random_string resource) so the
  # storage account name - and therefore its resource ID - is fully known at
  # plan time on first apply. A random_string resource's value is unknown
  # until it's created, which would make the account name (and the ID derived
  # from it) unknown too, breaking the for_each Foundry's BYOR wiring uses to
  # decide whether to create or link this account.
  name_hash            = substr(sha1("${local.resource_group_id}:${var.workload}:${var.environment}"), 0, 5)
  max_workload_length  = max(1, 24 - length("st") - length(local.environment_name) - length(local.name_hash))
  workload_name        = length(local.workload_name_raw) > 0 ? substr(local.workload_name_raw, 0, local.max_workload_length) : "tv"
  storage_account_name = "st${local.workload_name}${local.environment_name}${local.name_hash}"
}

module "this" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.2"

  name      = local.storage_account_name
  location  = var.location
  parent_id = local.resource_group_id
  tags      = local.tags

  account_sku_name                = null
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  public_network_access_enabled   = true
  network_rules                   = null
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  enable_telemetry                = true

  private_endpoints = {
    blob = {
      name               = "pep-blob-${local.name_suffix}"
      subnet_resource_id = var.pe_subnet_id
      subresource_name   = "blob"
      tags               = local.tags
    }
  }
}
