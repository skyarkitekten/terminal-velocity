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

# Preserve state across the AVM-everywhere swap: each core module now wraps an
# Azure Verified Module instead of a hand-rolled resource, so the underlying
# resource address moves one level deeper without a destroy/recreate.
moved {
  from = module.resource_group.azurerm_resource_group.this
  to   = module.resource_group.module.this.azapi_resource.this
}

moved {
  from = module.log_analytics.azurerm_log_analytics_workspace.this
  to   = module.log_analytics.module.this.azurerm_log_analytics_workspace.this
}

moved {
  from = module.application_insights.azurerm_application_insights.this
  to   = module.application_insights.module.this.azurerm_application_insights.this
}

moved {
  from = module.user_assigned_identity.azurerm_user_assigned_identity.this
  to   = module.user_assigned_identity.module.this.azurerm_user_assigned_identity.this
}

data "azurerm_client_config" "current" {}

# --- Networking ---
#
# One VNet + one private-endpoint subnet per environment. Simple topology: no
# hub-spoke, no on-prem connectivity. Exists solely to host the private
# endpoints for the BYOR data services and the Foundry account below.

module "networking" {
  source = "../../modules/networking"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
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

# --- Identity ---

module "user_assigned_identity" {
  source = "../../modules/user_assigned_identity"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

# --- BYOR data services ---
#
# Key Vault, Storage Account, Cosmos DB, and AI Search are provisioned as our
# own resources (Bring Your Own Resource) rather than left for the Foundry
# pattern module to create and own. Each gets a private endpoint into the PE
# subnet above; public network access stays enabled on all four because the
# GitHub Actions OIDC CD runners have no VNet line-of-sight — the private
# endpoints are additive, not the sole access path.

module "key_vault" {
  source = "../../modules/key_vault"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.id
  tags                = var.tags

  pe_subnet_id = module.networking.pe_subnet_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
}

module "storage_account" {
  source = "../../modules/storage_account"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags

  pe_subnet_id = module.networking.pe_subnet_id
}

module "cosmos_db" {
  source = "../../modules/cosmos_db"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags

  pe_subnet_id = module.networking.pe_subnet_id
}

module "ai_search" {
  source = "../../modules/ai_search"

  workload            = "terminal-velocity"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags

  pe_subnet_id = module.networking.pe_subnet_id
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

  key_vault_id       = module.key_vault.resource_id
  storage_account_id = module.storage_account.id
  cosmosdb_id        = module.cosmos_db.id
  ai_search_id       = module.ai_search.id
  pe_subnet_id       = module.networking.pe_subnet_id

  model_deployments = var.model_deployments
}

# --- Identity & RBAC ---
#
# Least-privilege, keyless RBAC: the agent runtime identity gets the Foundry
# data-plane role; the CI deploy principal gets the role to publish agents.

module "identity_rbac" {
  source = "../../modules/identity_rbac"

  foundry_account_id         = module.ai_foundry.foundry_id
  agent_runtime_principal_id = module.user_assigned_identity.principal_id
  ci_deploy_principal_id     = var.ci_deploy_principal_id
}
