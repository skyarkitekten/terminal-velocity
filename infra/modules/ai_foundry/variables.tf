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
  description = "Azure region for all Foundry resources."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group to deploy into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostic settings."
}

variable "application_insights_id" {
  type        = string
  description = "Resource ID of the Application Insights instance."
}

variable "application_insights_name" {
  type        = string
  description = "Name of the Application Insights instance."
}

variable "application_insights_connection_string" {
  type        = string
  description = "Connection string for the Application Insights instance."
  sensitive   = true
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
  description = "Map of model deployments to create in the Foundry account."
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

variable "tags" {
  type        = map(string)
  description = "Base tags applied to resources."
}

variable "enable_telemetry" {
  type        = bool
  description = "Controls whether Azure Verified Module telemetry is enabled."
  default     = true
}
