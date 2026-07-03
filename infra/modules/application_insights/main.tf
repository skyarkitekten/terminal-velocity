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

module "this" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.4.0"

  name                = "appi-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = local.tags
  enable_telemetry    = true
}
