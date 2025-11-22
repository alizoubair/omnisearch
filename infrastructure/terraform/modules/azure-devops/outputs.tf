output "project_id" {
  description = "ID of the Azure DevOps project"
  value       = var.create_azure_devops ? azuredevops_project.main[0].id : null
}

output "project_name" {
  description = "Name of the Azure DevOps project"
  value       = var.create_azure_devops ? azuredevops_project.main[0].name : null
}

output "backend_pipeline_id" {
  description = "ID of the backend CI/CD pipeline"
  value       = var.create_azure_devops && var.enable_backend_pipeline && var.devops_use_external_repository && var.devops_github_personal_access_token != "" && var.acr_name != "" ? azuredevops_build_definition.backend_ci[0].id : null
}

output "frontend_pipeline_id" {
  description = "ID of the frontend CI/CD pipeline"
  value       = var.create_azure_devops && var.enable_frontend_pipeline && var.devops_use_external_repository && var.devops_github_personal_access_token != "" && var.acr_name != "" ? azuredevops_build_definition.frontend_ci[0].id : null
}

output "github_service_connection_id" {
  description = "ID of the GitHub service connection"
  value       = var.create_azure_devops && var.devops_use_external_repository && var.devops_github_personal_access_token != "" ? (length(azuredevops_serviceendpoint_github.github) > 0 ? azuredevops_serviceendpoint_github.github[0].id : null) : null
}

output "acr_service_connection_id" {
  description = "ID of the ACR service connection"
  value       = var.create_azure_devops && var.acr_name != "" ? (length(azuredevops_serviceendpoint_azurecr.acr) > 0 ? azuredevops_serviceendpoint_azurecr.acr[0].id : null) : null
}

output "azurerm_service_connection_id" {
  description = "ID of the Azure RM service connection"
  value       = var.create_azure_devops ? (length(azuredevops_serviceendpoint_azurerm.main) > 0 ? azuredevops_serviceendpoint_azurerm.main[0].id : null) : null
}

output "service_principal_client_id" {
  description = "Client ID of the service principal"
  value       = var.create_azure_devops ? azuread_service_principal.devops[0].client_id : null
}

output "service_principal_object_id" {
  description = "Object ID of the service principal"
  value       = var.create_azure_devops ? azuread_service_principal.devops[0].object_id : null
}

output "service_principal_secret" {
  description = "Secret of the service principal"
  value       = var.create_azure_devops ? azuread_service_principal_password.devops[0].value : null
  sensitive   = true
}

# Self-hosted Agent Pool Outputs
output "frontend_agent_pool_id" {
  description = "ID of the frontend agent pool"
  value       = var.create_azure_devops ? azuredevops_agent_pool.frontend[0].id : null
}

output "backend_agent_pool_id" {
  description = "ID of the backend agent pool"
  value       = var.create_azure_devops ? azuredevops_agent_pool.backend[0].id : null
}

