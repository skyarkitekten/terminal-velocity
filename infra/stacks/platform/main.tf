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
