# Application Insights module.
#
# Provisions a workspace-backed Application Insights instance for agent
# telemetry and Foundry observability.

locals {
  name_suffix = "${var.workload}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = local.tags
}
