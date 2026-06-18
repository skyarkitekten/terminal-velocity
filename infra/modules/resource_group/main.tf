# Resource group module.
#
# A reusable building block: given an environment, location, and base tags it
# derives the standard name (`rg-<workload>-<environment>`) and applies the
# tags the subscription policy requires (Owner, Purpose, BillingCode come in
# via var.tags; Environment/ManagedBy are added here).

locals {
  name_suffix = "${var.workload}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}
