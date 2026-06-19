# Provider configuration. Stack/root level only — never in modules.
# Subscription/tenant come from variables (fed by ARM_*/TF_VAR_* in CI), not
# literals, so the same stack targets any environment.

provider "azurerm" {
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azapi" {}

provider "time" {}
