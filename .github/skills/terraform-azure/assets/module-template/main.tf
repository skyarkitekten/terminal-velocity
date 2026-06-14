# Module template: <module_name>
#
# Environment-agnostic, reusable resources. Compose this module per environment
# from a stack root; do not hardcode environment-specific values here.
#
# Replace the example resource group below with the resources this module owns.
# Derive Azure resource names from variables — never hardcode them.

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
