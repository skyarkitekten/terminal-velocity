# Terminal Velocity — platform stack.
#
# The deployable composition root CI plans/applies. It holds no raw resources:
# it wires reusable modules together and passes environment inputs through. The
# walking skeleton is a single resource group that proves the GitOps delivery
# loop (OIDC login -> backend state -> plan/apply -> dev/prod promotion) end to
# end. Real workload modules compose in here as they land.

module "resource_group" {
  source = "../../modules/resource_group"

  workload    = "terminal-velocity"
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

# Preserve state when the resource group moved from an inline resource into the
# resource_group module. Keeps the migration a no-op (no destroy/recreate).
moved {
  from = azurerm_resource_group.main
  to   = module.resource_group.azurerm_resource_group.this
}

# --- Observability ---

module "log_analytics" {
  source = "../../modules/log_analytics"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "application_insights" {
  source = "../../modules/application_insights"

  workload                   = "terminal-velocity"
  environment                = var.environment
  location                   = var.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = var.tags
}

# --- AI Foundry ---

module "ai_foundry" {
  source = "../../modules/ai_foundry"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_id   = module.resource_group.id
  resource_group_name = module.resource_group.name
  tags                = var.tags

  log_analytics_workspace_id             = module.log_analytics.id
  application_insights_id                = module.application_insights.id
  application_insights_name              = module.application_insights.name
  application_insights_connection_string = module.application_insights.connection_string

  model_deployments = var.model_deployments
}
