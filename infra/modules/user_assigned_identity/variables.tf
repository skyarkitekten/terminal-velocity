# Inputs for the user_assigned_identity module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the identity name (id-<workload>-<environment>)."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive the identity name."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the managed identity."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the identity into."
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the managed identity."
}
