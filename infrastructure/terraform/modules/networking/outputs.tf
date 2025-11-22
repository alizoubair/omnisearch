output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "presentation_subnet_id" {
  description = "ID of the presentation tier subnet"
  value       = azurerm_subnet.presentation.id
}

output "application_subnet_id" {
  description = "ID of the application tier subnet"
  value       = azurerm_subnet.application.id
}

output "data_subnet_id" {
  description = "ID of the data tier subnet"
  value       = azurerm_subnet.data.id
}

output "app_gateway_subnet_id" {
  description = "ID of the application gateway subnet"
  value       = var.create_app_gateway_subnet ? azurerm_subnet.app_gateway[0].id : null
}

output "bastion_subnet_id" {
  description = "ID of the bastion subnet"
  value       = var.create_bastion_subnet ? azurerm_subnet.bastion[0].id : null
}

output "managed_devops_pool_subnet_id" {
  description = "ID of the managed DevOps pool subnet"
  value       = var.create_managed_devops_pool_subnet ? azurerm_subnet.managed_devops_pool[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip_address" {
  description = "Public IP address of the NAT gateway"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat_gateway[0].ip_address : null
}

