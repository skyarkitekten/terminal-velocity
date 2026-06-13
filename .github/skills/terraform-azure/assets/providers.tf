# Provider configuration. Lives only at the stack/root level, never in modules.
# Source subscription/tenant from variables or the environment — not literals.

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

variable "subscription_id" {
  type        = string
  description = "Target Azure subscription ID. Prefer ARM_SUBSCRIPTION_ID in CI."
  default     = null
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Prefer ARM_TENANT_ID in CI."
  default     = null
}
