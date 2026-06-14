# Provider configuration. Stack/root level only — never in modules.
# Subscription/tenant come from variables (fed by ARM_*/TF_VAR_* in CI), not
# literals, so the same stack targets any environment.

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
