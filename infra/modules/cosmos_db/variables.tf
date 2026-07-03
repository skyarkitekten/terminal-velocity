# Inputs for the cosmos_db module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the Cosmos DB account name (cosmos-<workload>-<environment>)."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive the Cosmos DB account name."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the Cosmos DB account."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the Cosmos DB account into."

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must be a non-empty string."
  }
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the Cosmos DB account and private endpoint."
}

variable "pe_subnet_id" {
  type        = string
  description = "Resource ID of the subnet that hosts the Cosmos DB private endpoint."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.pe_subnet_id))
    error_message = "pe_subnet_id must be a valid Azure subnet resource ID."
  }
}

variable "free_tier_enabled" {
  type        = bool
  description = "Whether to enable Cosmos DB free tier. Leave disabled by default because only one free-tier account is allowed per subscription."
  default     = false
}

variable "consistency_level" {
  type        = string
  description = "Consistency level for the Cosmos DB account. Defaults to Session, which matches the Cosmos DB service default."
  default     = "Session"

  validation {
    condition     = contains(["BoundedStaleness", "ConsistentPrefix", "Eventual", "Session", "Strong"], var.consistency_level)
    error_message = "consistency_level must be one of: BoundedStaleness, ConsistentPrefix, Eventual, Session, Strong."
  }
}
