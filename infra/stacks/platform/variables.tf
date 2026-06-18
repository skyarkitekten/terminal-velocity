# Input variables for the Terminal Velocity root stack.

variable "subscription_id" {
  type        = string
  description = "Target Azure subscription ID. Fed by ARM_SUBSCRIPTION_ID/TF_VAR_subscription_id in CI."
  default     = null
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Fed by ARM_TENANT_ID/TF_VAR_tenant_id in CI."
  default     = null
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive resource names."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the stack's resources."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region (e.g. \"northcentralus\")."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources. Must satisfy subscription policy (Owner, Purpose, BillingCode)."
}
