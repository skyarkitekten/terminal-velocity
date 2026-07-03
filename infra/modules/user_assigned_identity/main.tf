# User-assigned managed identity module.
#
# Provisions a standalone user-assigned managed identity (id-<workload>-<env>)
# for the agent runtime / delivery pipeline. It receives the Foundry data-plane
# role via the identity_rbac module and exposes a stable client_id that workloads
# (e.g. agent compute the delivery pipeline assigns it to) authenticate as —
# keyless, no stored credentials.

locals {
  name_suffix = "${var.workload}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "this" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.0"

  name                = "id-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  enable_telemetry = true
}
