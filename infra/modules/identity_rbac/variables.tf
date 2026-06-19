# Inputs for the identity_rbac module.

variable "foundry_account_id" {
  type        = string
  description = "Resource ID of the Foundry (Cognitive Services) account that role assignments are scoped to."
}

variable "agent_runtime_principal_id" {
  type        = string
  description = "Principal (object) ID of the agent runtime managed identity that receives the Foundry data-plane role."
}

variable "ci_deploy_principal_id" {
  type        = string
  description = "Principal (object) ID of the CI deploy service principal that publishes agents. When null, the CI role assignment is skipped."
  default     = null
}

variable "agent_runtime_role_definition_id" {
  type        = string
  description = "Built-in role definition GUID granted to the agent runtime identity. Defaults to Foundry User (formerly Azure AI User)."
  default     = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
}

variable "ci_deploy_role_definition_id" {
  type        = string
  description = "Built-in role definition GUID granted to the CI deploy principal. Defaults to Foundry Project Manager (formerly Azure AI Project Manager), the minimum role to publish agents."
  default     = "eadc314b-1a2d-4efa-be10-5d325db5065e"
}
