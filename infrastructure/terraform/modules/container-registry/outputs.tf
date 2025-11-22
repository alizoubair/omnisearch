output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = var.create_container_registry ? azurerm_container_registry.acr[0].id : null
}

output "acr_resource_id" {
  description = "Resource ID of the Azure Container Registry"
  value       = var.create_container_registry ? azurerm_container_registry.acr[0].id : null
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = var.create_container_registry ? azurerm_container_registry.acr[0].name : null
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = var.create_container_registry ? azurerm_container_registry.acr[0].login_server : null
}

output "acr_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = var.create_container_registry && var.acr_admin_enabled ? azurerm_container_registry.acr[0].admin_username : null
}

output "acr_admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = var.create_container_registry && var.acr_admin_enabled ? azurerm_container_registry.acr[0].admin_password : null
  sensitive   = true
}

