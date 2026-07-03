# Log Analytics module.
#
# Provisions a workspace that serves as the central diagnostics sink for all
# platform resources including AI Foundry.

locals {
  name_suffix = "${var.workload}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "this" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                      = "law-${local.name_suffix}"
  location                                  = var.location
  resource_group_name                       = var.resource_group_name
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_retention_in_days = var.retention_days
  tags                                      = local.tags
  enable_telemetry                          = true
}
