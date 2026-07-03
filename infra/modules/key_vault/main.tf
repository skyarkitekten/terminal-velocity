# Key Vault module.
#
# Wraps the Azure Verified Module for Key Vault with repo naming/tagging
# conventions, RBAC-only data-plane authorization, purge protection, and a
# single private endpoint on the shared private endpoint subnet.

locals {
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  sanitized_workload    = trim(replace(replace(lower(var.workload), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
  sanitized_environment = trim(replace(replace(lower(var.environment), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")

  # Key Vault names must be globally unique and <= 24 characters, so keep the
  # readable kv-<workload>-<environment> prefix where possible and append a
  # stable hash suffix derived from deployment scope to avoid collisions.
  kv_name_prefix = trim(
    substr(
      replace(join("-", compact(["kv", local.sanitized_workload, local.sanitized_environment])), "/-+/", "-"),
      0,
      17
    ),
    "-"
  )
  kv_name_hash = substr(sha1(join(":", [var.tenant_id, var.resource_group_id, var.workload, var.environment])), 0, 6)
  kv_name      = "${local.kv_name_prefix}-${local.kv_name_hash}"
}

module "this" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = local.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  tags                = local.tags

  legacy_access_policies_enabled = false
  purge_protection_enabled       = true
  soft_delete_retention_days     = 90
  enable_telemetry               = true

  # Keep public access enabled while CI runners and operators still reach the
  # vault outside the VNet; once delivery paths are VNet-integrated we can turn
  # this off and rely solely on private connectivity.
  public_network_access_enabled = true
  network_acls                  = null

  # Leave private DNS zone group management to shared networking / policy until
  # the platform stack owns those zones explicitly.
  private_endpoints_manage_dns_zone_group = false
  private_endpoints = {
    # The AVM hard-codes the Key Vault private link subresource to ["vault"].
    vault = {
      subnet_resource_id = var.pe_subnet_id
      tags               = local.tags
    }
  }
}
