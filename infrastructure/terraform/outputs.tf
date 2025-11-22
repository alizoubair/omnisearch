# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Remote State Outputs
output "remote_state_storage_account_name" {
  description = "Name of the storage account for Terraform remote state"
  value       = module.remote_state.storage_account_name
}

output "remote_state_container_name" {
  description = "Name of the storage container for Terraform remote state"
  value       = module.remote_state.container_name
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "presentation_subnet_id" {
  description = "ID of the presentation tier subnet"
  value       = module.networking.presentation_subnet_id
}

output "application_subnet_id" {
  description = "ID of the application tier subnet"
  value       = module.networking.application_subnet_id
}

output "data_subnet_id" {
  description = "ID of the data tier subnet"
  value       = module.networking.data_subnet_id
}

# Load Balancing Outputs
output "application_gateway_id" {
  description = "ID of the application gateway"
  value       = module.load_balancing.application_gateway_id
}

output "application_gateway_public_ip_address" {
  description = "Public IP address of the application gateway"
  value       = module.load_balancing.application_gateway_public_ip_address
}

output "internal_lb_id" {
  description = "ID of the internal load balancer"
  value       = module.load_balancing.internal_lb_id
}

output "internal_lb_private_ip" {
  description = "Private IP address of the internal load balancer"
  value       = module.load_balancing.internal_lb_private_ip
}

# Database Outputs
output "database_server_id" {
  description = "ID of the database server"
  value       = module.database.primary_server_id
}

output "database_server_fqdn" {
  description = "FQDN of the database server"
  value       = module.database.primary_server_fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.database_name
}

# Container Registry Outputs
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.container_registry.acr_name
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = module.container_registry.acr_login_server
}

# Key Vault Outputs
output "key_vault_id" {
  description = "ID of the key vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = module.key_vault.key_vault_uri
}

# AI Services Outputs
output "openai_endpoint" {
  description = "Endpoint of the OpenAI service"
  value       = module.ai_services.openai_endpoint
}

output "document_intelligence_endpoint" {
  description = "Endpoint of the Document Intelligence service"
  value       = module.ai_services.document_intelligence_endpoint
}

output "ai_search_endpoint" {
  description = "Endpoint of the AI Search service"
  value       = module.ai_services.ai_search_endpoint
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = module.monitoring.application_insights_id
}

# Azure DevOps Outputs
output "azure_devops_project_id" {
  description = "ID of the Azure DevOps project"
  value       = module.azure_devops.project_id
}

output "backend_pipeline_id" {
  description = "ID of the backend CI/CD pipeline"
  value       = module.azure_devops.backend_pipeline_id
}

output "frontend_pipeline_id" {
  description = "ID of the frontend CI/CD pipeline"
  value       = module.azure_devops.frontend_pipeline_id
}

# Compute Outputs
output "presentation_vmss_id" {
  description = "ID of the presentation tier VM scale set"
  value       = module.compute.presentation_vmss_id
}

output "application_vmss_id" {
  description = "ID of the application tier VM scale set"
  value       = module.compute.application_vmss_id
}

output "bastion_host_id" {
  description = "ID of the Azure Bastion host"
  value       = module.compute.bastion_host_id
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion host"
  value       = module.compute.bastion_public_ip
}

# Web URL (if Application Gateway is deployed)
output "web_url" {
  description = "Web application URL"
  value       = var.create_application_gateway ? "http://${module.load_balancing.application_gateway_public_ip_address}" : null
}

# API Endpoint (if Internal Load Balancer is deployed)
output "api_endpoint" {
  description = "API endpoint URL"
  value       = var.create_internal_lb ? "http://${module.load_balancing.internal_lb_private_ip}:${var.internal_lb_backend_port}" : null
}


