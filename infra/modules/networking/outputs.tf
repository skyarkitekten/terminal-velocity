# Outputs for the networking module.

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.this.resource_id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = module.this.name
}

output "pe_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = module.this.subnets["private_endpoints"].resource_id
}

output "pe_subnet_name" {
  description = "Name of the private endpoint subnet."
  value       = module.this.subnets["private_endpoints"].name
}
