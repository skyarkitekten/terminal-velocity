# Inputs for the ai_search module.

variable "workload" {
  type        = string
  description = "Workload name used to derive the search service name (srch-<workload>-<environment>)."

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod). Used to derive the search service name."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the search service."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the search service into."
}

variable "tags" {
  type        = map(string)
  description = "Base tags applied to the search service."
}

variable "pe_subnet_id" {
  type        = string
  description = "Resource ID of the subnet the private endpoint for the search service is deployed into."

  validation {
    condition     = length(trimspace(var.pe_subnet_id)) > 0
    error_message = "pe_subnet_id must be a non-empty resource ID."
  }
}

variable "sku" {
  type        = string
  description = <<-DESCRIPTION
    Pricing tier of the search service. One of: free, basic, standard, standard2,
    standard3, storage_optimized_l1, storage_optimized_l2.

    Defaults to `basic`. The `free` tier is deliberately excluded from the
    allowed set: this module always provisions a private endpoint, and per the
    Azure AI Search SKU documentation the `free` tier does not support private
    endpoints for inbound connections
    (https://learn.microsoft.com/azure/search/search-sku-tier), so choosing it
    here would fail at apply time.
  DESCRIPTION
  default     = "basic"

  validation {
    condition     = contains(["basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.sku)
    error_message = "sku must be one of: basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2 (free is unsupported here because this module always creates a private endpoint)."
  }
}

variable "replica_count" {
  type        = number
  description = "Number of replicas distributing search workloads. Defaults to 1; increase for query high availability (not applicable to the free tier)."
  default     = 1

  validation {
    condition     = var.replica_count >= 1 && var.replica_count <= 12
    error_message = "replica_count must be between 1 and 12."
  }
}

variable "partition_count" {
  type        = number
  description = "Number of partitions sharding the index for document count scaling and faster indexing. Defaults to 1."
  default     = 1

  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.partition_count)
    error_message = "partition_count must be one of: 1, 2, 3, 4, 6, 12."
  }
}
