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

variable "ci_deploy_principal_id" {
  type        = string
  description = "Object (principal) ID of the CI deploy service principal granted the Foundry Project Manager role to publish agents. Fed by TF_VAR_ci_deploy_principal_id (AZURE_CI_PRINCIPAL_ID) in CI. When null, the CI role assignment is skipped."
  default     = null
}

variable "model_deployments" {
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = number
    })
  }))
  description = "Map of model deployments for the AI Foundry account."
  default = {
    "gpt-4.1-mini" = {
      name = "gpt-4.1-mini"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1-mini"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10
      }
    }
  }
}
