# Input variables for <module_name>.
# Every variable has a type and description. Add `default` only when a sane one
# exists, and a `validation` block for constrained inputs. Mark secrets sensitive.

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group this module manages."
}

variable "location" {
  type        = string
  description = "Azure region for resources in this module."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region (e.g. \"westeurope\")."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}
