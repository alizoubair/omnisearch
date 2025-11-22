terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# Azure AD Application for DevOps Service Principal
resource "azuread_application" "devops" {
  count        = var.create_azure_devops ? 1 : 0
  display_name = "${replace(var.resource_group_name, "rg-", "")}-sp"
  description  = "Service principal for Azure DevOps pipelines in ${replace(var.resource_group_name, "rg-", "")}"
}

# Azure AD Service Principal
resource "azuread_service_principal" "devops" {
  count          = var.create_azure_devops ? 1 : 0
  client_id      = azuread_application.devops[0].client_id
}

# Azure AD Service Principal Password
resource "azuread_service_principal_password" "devops" {
  count                = var.create_azure_devops ? 1 : 0
  service_principal_id = azuread_service_principal.devops[0].object_id
}

# Get current Azure client config
data "azurerm_client_config" "current" {}

# Random password for NextAuth secret (32 characters, alphanumeric)
resource "random_password" "nextauth_secret" {
  length  = 32
  special = false # NextAuth secret should be alphanumeric only
}

# Get current Azure subscription
data "azurerm_subscription" "current" {}

# Azure DevOps Project
resource "azuredevops_project" "main" {
  count              = var.create_azure_devops ? 1 : 0
  name               = "omnisearch"
  description        = "Omnisearch AI Services Project"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

# GitHub Service Connection
resource "azuredevops_serviceendpoint_github" "github" {
  count              = var.create_azure_devops && var.devops_use_external_repository && var.devops_github_personal_access_token != "" ? 1 : 0
  project_id         = azuredevops_project.main[0].id
  service_endpoint_name = var.devops_github_service_connection_name != "" ? var.devops_github_service_connection_name : "GitHub-${replace(var.resource_group_name, "rg-", "")}"
  description        = "GitHub service connection for ${replace(var.resource_group_name, "rg-", "")}"
  auth_personal {
    personal_access_token = var.devops_github_personal_access_token
  }
}

# Azure RM Service Connection (for Azure resources)
resource "azuredevops_serviceendpoint_azurerm" "main" {
  count                  = var.create_azure_devops ? 1 : 0
  project_id             = azuredevops_project.main[0].id
  service_endpoint_name  = "azure-${replace(var.resource_group_name, "rg-", "")}"
  description            = "Azure Resource Manager connection for ${replace(var.resource_group_name, "rg-", "")}"
  credentials {
    serviceprincipalid  = azuread_service_principal.devops[0].client_id
    serviceprincipalkey = azuread_service_principal_password.devops[0].value
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

# ACR Service Connection
# Uses service principal authentication - credentials are managed by Azure DevOps
# The service connection will use the service principal with AcrPush role
resource "azuredevops_serviceendpoint_azurecr" "acr" {
  count              = var.create_azure_devops && var.acr_name != "" ? 1 : 0
  project_id         = azuredevops_project.main[0].id
  service_endpoint_name = "acr-${replace(var.resource_group_name, "rg-", "")}-connection"
  description        = "Azure Container Registry connection for ${replace(var.resource_group_name, "rg-", "")}"
  resource_group     = var.resource_group_name
  azurecr_name       = var.acr_name
  azurecr_subscription_id = data.azurerm_client_config.current.subscription_id
  azurecr_subscription_name = data.azurerm_subscription.current.display_name
  azurecr_spn_tenantid = data.azurerm_client_config.current.tenant_id

  depends_on = [
    azuread_service_principal.devops,
    azurerm_role_assignment.devops_acr_push
  ]
}

# Azure DevOps Variable Groups
resource "azuredevops_variable_group" "common" {
  count       = var.create_azure_devops ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  name        = "Common-Variables"
  description = "Common variables used across all pipelines (NEXTAUTH_URL auto-set from Application Gateway)"
  allow_access = true

  variable {
    name  = "AZURE_SUBSCRIPTION_ID"
    value = data.azurerm_client_config.current.subscription_id
  }

  variable {
    name  = "AZURE_TENANT_ID"
    value = data.azurerm_client_config.current.tenant_id
  }

  variable {
    name  = "PROJECT_NAME"
    value = "${replace(var.resource_group_name, "rg-", "")}"
  }

  variable {
    name  = "TERRAFORM_VERSION"
    value = "1.5.0"
  }
}

resource "azuredevops_variable_group" "dev" {
  count       = var.create_azure_devops ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  name        = "Development-Variables"
  description = "Variables for development environment"
  allow_access = true

  depends_on = [
    azuredevops_serviceendpoint_azurecr.acr,
    azuread_service_principal.devops
  ]

  variable {
    name  = "ACR_NAME"
    value = var.acr_name
  }

  variable {
    name  = "ACR_SERVICE_CONNECTION"
    value = var.acr_name != "" && length(azuredevops_serviceendpoint_azurecr.acr) > 0 ? azuredevops_serviceendpoint_azurecr.acr[0].service_endpoint_name : ""
  }

  variable {
    name  = "ACR_USERNAME"
    value = var.acr_name
  }

  variable {
    name  = "AI_SEARCH_ENDPOINT"
    value = var.ai_search_endpoint != null ? var.ai_search_endpoint : ""
  }

  variable {
    name  = "AZURE_AD_CLIENT_ID"
    value = var.create_azure_devops ? azuread_service_principal.devops[0].client_id : ""
  }

  variable {
    name  = "AZURE_AD_TENANT_ID"
    value = data.azurerm_client_config.current.tenant_id
  }

  variable {
    name  = "ENVIRONMENT"
    value = "dev"
  }

  variable {
    name  = "LOCATION"
    value = lower(replace(var.location, " ", ""))
  }

  variable {
    name  = "NEXTAUTH_URL"
    # Construct from Application Gateway public IP if available
    # Format: http://<public-ip>
    value = var.application_gateway_public_ip != "" ? "http://${var.application_gateway_public_ip}" : ""
  }

  variable {
    name  = "OPENAI_ENDPOINT"
    value = var.openai_endpoint != null ? var.openai_endpoint : ""
  }

  variable {
    name  = "RESOURCE_GROUP_NAME"
    value = "${var.resource_group_name}-dev"
  }

  variable {
    name  = "TERRAFORM_STATE_CONTAINER"
    value = "tfstate"
  }

  variable {
    name  = "TERRAFORM_STATE_KEY"
    value = "dev/terraform.tfstate"
  }

  variable {
    name  = "TERRAFORM_STATE_STORAGE_ACCOUNT"
    value = ""
  }
}

resource "azuredevops_variable_group" "secrets" {
  count       = var.create_azure_devops ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  name        = "Secrets"
  description = "Secure variables and secrets (updated: NEXTAUTH_SECRET auto-generated)"
  allow_access = true

  depends_on = [
    azuread_service_principal.devops,
    azuread_service_principal_password.devops
  ]

  variable {
    name        = "NEXT_PUBLIC_API_BASE_URL"
    value       = var.internal_lb_private_ip != null ? "http://${var.internal_lb_private_ip}:${var.internal_lb_frontend_port}" : ""
    is_secret   = false
  }

  variable {
    name        = "SERVICE_PRINCIPAL_ID"
    value       = var.create_azure_devops ? azuread_service_principal.devops[0].client_id : ""
    is_secret   = false
  }

  variable {
    name        = "ACR_PASSWORD"
    value       = var.acr_admin_password != null ? var.acr_admin_password : ""
    is_secret   = true
  }

  variable {
    name        = "AI_SEARCH_KEY"
    value       = var.ai_search_admin_key != null ? var.ai_search_admin_key : ""
    is_secret   = true
  }

  variable {
    name        = "AZURE_AD_CLIENT_SECRET"
    value       = var.create_azure_devops ? azuread_service_principal_password.devops[0].value : ""
    is_secret   = true
  }

  variable {
    name        = "DATABASE_URL"
    value       = var.database_url != null ? var.database_url : ""
    is_secret   = false  # Set to false for debugging - can see value in Azure DevOps
  }

  variable {
    name        = "NEXTAUTH_SECRET"
    value       = var.nextauth_secret != null ? var.nextauth_secret : random_password.nextauth_secret.result
    is_secret   = true
  }

  variable {
    name        = "OPENAI_API_KEY"
    value       = var.openai_api_key != null ? var.openai_api_key : ""
    is_secret   = true
  }

  variable {
    name        = "OPENAI_KEY"
    value       = var.openai_api_key != null ? var.openai_api_key : ""
    is_secret   = true
  }

  variable {
    name        = "SERVICE_PRINCIPAL_SECRET"
    value       = var.create_azure_devops ? azuread_service_principal_password.devops[0].value : ""
    is_secret   = true
  }

  variable {
    name        = "SSH_PUBLIC_KEY"
    value       = var.ssh_public_key
    is_secret   = true
  }

  variable {
    name        = "STORAGE_CONNECTION_STRING"
    value       = var.storage_connection_string != null ? var.storage_connection_string : ""
    is_secret   = true
  }
}

# Backend Pipeline
resource "azuredevops_build_definition" "backend_ci" {
  count      = var.create_azure_devops && var.enable_backend_pipeline && var.devops_use_external_repository && var.devops_github_personal_access_token != "" && var.acr_name != "" ? 1 : 0
  project_id = azuredevops_project.main[0].id
  name       = "Backend-CI-CD"
  path       = "\\Applications"

  repository {
    repo_type   = "GitHub"
    repo_id     = var.devops_external_repository_url
    branch_name = "refs/heads/main"
    yml_path    = "infrastructure/pipelines/azure-pipelines-backend.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github[0].id
    report_build_status = true
  }

  ci_trigger {
    use_yaml = true
  }

  variable_groups = [
    azuredevops_variable_group.secrets[0].id,
    azuredevops_variable_group.common[0].id,
    azuredevops_variable_group.dev[0].id
  ]
}

# Frontend Pipeline
resource "azuredevops_build_definition" "frontend_ci" {
  count      = var.create_azure_devops && var.enable_frontend_pipeline && var.devops_use_external_repository && var.devops_github_personal_access_token != "" && var.acr_name != "" ? 1 : 0
  project_id = azuredevops_project.main[0].id
  name       = "Frontend-CI-CD"
  path       = "\\Applications"

  repository {
    repo_type   = "GitHub"
    repo_id     = var.devops_external_repository_url
    branch_name = "refs/heads/main"
    yml_path    = "infrastructure/pipelines/azure-pipelines-frontend.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github[0].id
    report_build_status = true
  }

  ci_trigger {
    use_yaml = true
  }

  variable_groups = [
    azuredevops_variable_group.secrets[0].id,
    azuredevops_variable_group.common[0].id,
    azuredevops_variable_group.dev[0].id
  ]
}

# Role Assignments for Service Principal
# Contributor role on Resource Group
resource "azurerm_role_assignment" "devops_contributor" {
  count                = var.create_azure_devops ? 1 : 0
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.devops[0].object_id
}

# ACR Pull role for Service Principal
resource "azurerm_role_assignment" "devops_acr_pull" {
  count                = var.create_azure_devops && var.create_container_registry ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.devops[0].object_id
}

# ACR Push role for Service Principal
resource "azurerm_role_assignment" "devops_acr_push" {
  count                = var.create_azure_devops && var.create_container_registry ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.devops[0].object_id
}

# Self-hosted Agent Pools (Organization-scoped)
# Note: Organization-scoped pools are available to all projects by default
# If pipelines can't find the pool, check pool name matches exactly in YAML
resource "azuredevops_agent_pool" "frontend" {
  count          = var.create_azure_devops ? 1 : 0
  name           = var.frontend_agent_pool_name != "" ? var.frontend_agent_pool_name : "frontend-vms"
  auto_provision = false
  auto_update    = true
  # Organization-scoped pools don't need project_id
  # They are available to all projects in the organization
}

resource "azuredevops_agent_pool" "backend" {
  count          = var.create_azure_devops ? 1 : 0
  name           = var.backend_agent_pool_name != "" ? var.backend_agent_pool_name : "backend-vms"
  auto_provision = false
  auto_update    = true
  # Organization-scoped pools don't need project_id
  # They are available to all projects in the organization
}

# Agent Queues (Project-scoped resources that link organization pools to projects)
resource "azuredevops_agent_queue" "frontend" {
  count         = var.create_azure_devops ? 1 : 0
  project_id    = azuredevops_project.main[0].id
  agent_pool_id = azuredevops_agent_pool.frontend[0].id
}

resource "azuredevops_agent_queue" "backend" {
  count         = var.create_azure_devops ? 1 : 0
  project_id    = azuredevops_project.main[0].id
  agent_pool_id = azuredevops_agent_pool.backend[0].id
}

# Pipeline Authorizations for Agent Queues
# Authorize all pipelines in the project to use the agent queues
resource "azuredevops_pipeline_authorization" "frontend_queue" {
  count       = var.create_azure_devops ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  resource_id = azuredevops_agent_queue.frontend[0].id
  type        = "queue"
  
  depends_on = [
    azuredevops_agent_queue.frontend
  ]
}

resource "azuredevops_pipeline_authorization" "backend_queue" {
  count       = var.create_azure_devops ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  resource_id = azuredevops_agent_queue.backend[0].id
  type        = "queue"
  
  depends_on = [
    azuredevops_agent_queue.backend
  ]
}

# Pipeline Authorization for ACR Service Connection
# Authorize all pipelines to use the connection
resource "azuredevops_pipeline_authorization" "acr_service_connection" {
  count       = var.create_azure_devops && var.acr_name != "" ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  resource_id = azuredevops_serviceendpoint_azurecr.acr[0].id
  type        = "endpoint"
  
  depends_on = [
    azuredevops_serviceendpoint_azurecr.acr
  ]
}

# Pipeline Authorization for Variable Groups
# Authorize frontend pipeline to use the variable groups
resource "azuredevops_pipeline_authorization" "frontend_secrets_variable_group" {
  count       = var.create_azure_devops && var.enable_frontend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.frontend_ci[0].id
  resource_id = azuredevops_variable_group.secrets[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.frontend_ci,
    azuredevops_variable_group.secrets
  ]
}

resource "azuredevops_pipeline_authorization" "frontend_common_variable_group" {
  count       = var.create_azure_devops && var.enable_frontend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.frontend_ci[0].id
  resource_id = azuredevops_variable_group.common[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.frontend_ci,
    azuredevops_variable_group.common
  ]
}

resource "azuredevops_pipeline_authorization" "frontend_dev_variable_group" {
  count       = var.create_azure_devops && var.enable_frontend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.frontend_ci[0].id
  resource_id = azuredevops_variable_group.dev[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.frontend_ci,
    azuredevops_variable_group.dev
  ]
}

# Pipeline Authorization for Variable Groups
# Authorize backend pipeline to use the variable groups
resource "azuredevops_pipeline_authorization" "backend_secrets_variable_group" {
  count       = var.create_azure_devops && var.enable_backend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.backend_ci[0].id
  resource_id = azuredevops_variable_group.secrets[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.backend_ci,
    azuredevops_variable_group.secrets
  ]
}

resource "azuredevops_pipeline_authorization" "backend_common_variable_group" {
  count       = var.create_azure_devops && var.enable_backend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.backend_ci[0].id
  resource_id = azuredevops_variable_group.common[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.backend_ci,
    azuredevops_variable_group.common
  ]
}

resource "azuredevops_pipeline_authorization" "backend_dev_variable_group" {
  count       = var.create_azure_devops && var.enable_backend_pipeline ? 1 : 0
  project_id  = azuredevops_project.main[0].id
  pipeline_id = azuredevops_build_definition.backend_ci[0].id
  resource_id = azuredevops_variable_group.dev[0].id
  type        = "variablegroup"
  
  depends_on = [
    azuredevops_build_definition.backend_ci,
    azuredevops_variable_group.dev
  ]
}
