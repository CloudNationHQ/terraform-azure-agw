output "config" {
  description = "contains application gateway configuration"
  value       = azurerm_application_gateway.this
}

output "role_assignment" {
  description = "contains role assignment configuration"
  value       = azurerm_role_assignment.this
}

output "backend_address_pool_association" {
  description = "contains network interface backend address pool association configuration"
  value       = azurerm_network_interface_application_gateway_backend_address_pool_association.this
}
