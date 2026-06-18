# Inputs for the resource_group module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the resource group name (rg-<workload>-<environment>)."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive the resource group name."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the resource group."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region (e.g. \"northcentralus\")."
  }
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the resource group. Must satisfy subscription policy (Owner, Purpose, BillingCode)."
}
