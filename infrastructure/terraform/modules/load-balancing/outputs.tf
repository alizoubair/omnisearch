output "application_gateway_id" {
  description = "ID of the application gateway"
  value       = var.create_application_gateway ? azurerm_application_gateway.main[0].id : null
}

output "application_gateway_public_ip_address" {
  description = "Public IP address of the application gateway"
  value       = var.create_application_gateway ? azurerm_public_ip.app_gateway[0].ip_address : null
}

output "application_gateway_backend_address_pool_id" {
  description = "ID of the application gateway backend address pool"
  value       = var.create_application_gateway ? try([for pool in azurerm_application_gateway.main[0].backend_address_pool : pool.id if pool.name == "backend-pool"][0], null) : null
}

output "internal_lb_id" {
  description = "ID of the internal load balancer"
  value       = var.create_internal_lb ? azurerm_lb.internal[0].id : null
}

output "internal_lb_private_ip" {
  description = "Private IP address of the internal load balancer"
  value       = var.create_internal_lb ? azurerm_lb.internal[0].frontend_ip_configuration[0].private_ip_address : null
}

output "internal_lb_backend_address_pool_id" {
  description = "ID of the internal load balancer backend address pool"
  value       = var.create_internal_lb ? azurerm_lb_backend_address_pool.internal[0].id : null
}


