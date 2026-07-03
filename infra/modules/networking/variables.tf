# Inputs for the networking module.

variable "workload" {
  type        = string
  description = "Workload name used to derive resource names."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the virtual network."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into."
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the resource."
}

variable "address_space" {
  type        = list(string)
  description = "Address spaces applied to the virtual network so environments can use non-overlapping CIDR ranges."
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for prefix in var.address_space : can(cidrhost(prefix, 0))])
    error_message = "address_space must contain at least one valid CIDR block."
  }
}

variable "pe_subnet_address_prefix" {
  type        = string
  description = "CIDR prefix for the dedicated private endpoint subnet."
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.pe_subnet_address_prefix, 0))
    error_message = "pe_subnet_address_prefix must be a valid CIDR block."
  }
}
