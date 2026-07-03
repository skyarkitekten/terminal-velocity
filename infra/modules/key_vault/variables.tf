# Inputs for the key_vault module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the Key Vault name."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive the Key Vault name."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the Key Vault into."

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must be a non-empty string."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group. The upstream AVM deploys by resource_group_name, but this wrapper retains the ID for interface parity and to salt the deterministic Key Vault name hash."

  validation {
    condition     = length(trimspace(var.resource_group_id)) > 0
    error_message = "resource_group_id must be a non-empty resource ID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the Key Vault and its private endpoint."
}

variable "pe_subnet_id" {
  type        = string
  description = "Resource ID of the subnet that hosts the Key Vault private endpoint."

  validation {
    condition     = length(trimspace(var.pe_subnet_id)) > 0
    error_message = "pe_subnet_id must be a non-empty subnet resource ID."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID used by the Key Vault."

  validation {
    condition     = can(regex("(?i)^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid GUID."
  }
}
