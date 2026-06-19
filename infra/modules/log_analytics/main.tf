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

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = local.tags
}
