# Terminal Velocity root stack.
#
# Walking skeleton: a single resource group that proves the GitOps delivery
# loop (OIDC login -> backend state -> plan/apply -> dev/prod promotion) end to
# end. Real workload modules compose into this root once the loop is green.

locals {
  name_suffix = "terminal-velocity-${var.environment}"

  # Subscription policy requires Owner, Purpose, BillingCode on resource groups.
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.common_tags
}
