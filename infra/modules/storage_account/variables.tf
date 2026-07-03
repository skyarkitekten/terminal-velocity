# Inputs for the storage_account module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the storage account and private endpoint names."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
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
  description = "Azure region for the storage account and private endpoint."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the storage account into."

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must be a non-empty string."
  }
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the storage account and private endpoint."
}

variable "pe_subnet_id" {
  type        = string
  description = "Resource ID of the subnet used for the storage account private endpoint."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.pe_subnet_id))
    error_message = "pe_subnet_id must be a valid subnet resource ID."
  }
}

variable "account_tier" {
  type        = string
  description = "Storage account tier. Defaults to Standard for cost-conscious environments."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be one of: Standard, Premium."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Storage account replication type. Defaults to LRS for cost-conscious environments."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}
