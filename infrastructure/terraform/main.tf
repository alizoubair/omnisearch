# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}

# Remote State Module
module "remote_state" {
  source = "./modules/remote-state"

  create_remote_state  = var.create_remote_state
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_name = var.remote_state_storage_account_name
  container_name       = var.remote_state_container_name
  common_tags          = var.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  vnet_name                         = var.vnet_name
  vnet_address_space                = var.vnet_address_space
  presentation_subnet_name          = var.presentation_subnet_name
  presentation_subnet_prefixes      = var.presentation_subnet_prefixes
  application_subnet_name           = var.application_subnet_name
  application_subnet_prefixes       = var.application_subnet_prefixes
  data_subnet_name                  = var.data_subnet_name
  data_subnet_prefixes              = var.data_subnet_prefixes
  create_bastion_subnet             = var.create_bastion_subnet
  create_app_gateway_subnet         = var.create_app_gateway_subnet
  create_managed_devops_pool_subnet = var.create_managed_devops_pool_subnet
  create_nat_gateway                = var.create_nat_gateway
  nat_gateway_zones                 = var.nat_gateway_zones
  associate_nat_with_application    = var.associate_nat_with_application
  common_tags                       = var.common_tags
}

# Load Balancing Module
module "load_balancing" {
  source = "./modules/load-balancing"

  resource_group_name                    = azurerm_resource_group.main.name
  location                               = azurerm_resource_group.main.location
  vnet_name                              = module.networking.vnet_name
  application_subnet_id                  = module.networking.application_subnet_id
  presentation_subnet_id                 = module.networking.presentation_subnet_id
  app_gateway_subnet_id                  = module.networking.app_gateway_subnet_id
  create_application_gateway             = var.create_application_gateway
  enable_https_listener                  = var.enable_https_listener
  application_gateway_name               = var.application_gateway_name
  application_gateway_public_ip_name     = var.application_gateway_public_ip_name
  application_gateway_sku_name           = var.application_gateway_sku_name
  application_gateway_sku_tier           = var.application_gateway_sku_tier
  application_gateway_capacity           = var.application_gateway_capacity
  application_gateway_min_capacity       = var.application_gateway_min_capacity
  application_gateway_max_capacity       = var.application_gateway_max_capacity
  enable_app_gateway_autoscaling         = var.enable_app_gateway_autoscaling
  application_gateway_backend_port       = var.application_gateway_backend_port
  application_gateway_backend_https_port = var.application_gateway_backend_https_port
  application_gateway_probe_path         = var.application_gateway_probe_path
  create_internal_lb                     = var.create_internal_lb
  internal_lb_name                       = var.internal_lb_name
  internal_lb_private_ip                 = var.internal_lb_private_ip
  internal_lb_probe_path                 = var.internal_lb_probe_path
  internal_lb_frontend_port              = var.internal_lb_frontend_port
  internal_lb_backend_port               = var.internal_lb_backend_port
  internal_lb_probe_port                 = var.internal_lb_probe_port
  enable_internal_https_rule             = var.enable_internal_https_rule
  enable_nat_pool                        = var.enable_nat_pool
  nat_pool_frontend_port_start           = var.nat_pool_frontend_port_start
  nat_pool_frontend_port_end             = var.nat_pool_frontend_port_end
  nat_pool_backend_port                  = var.nat_pool_backend_port
  common_tags                            = var.common_tags
}

# Monitoring Module (must be created before database for diagnostic settings)
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name            = azurerm_resource_group.main.name
  location                       = azurerm_resource_group.main.location
  create_log_analytics_workspace = var.create_log_analytics_workspace
  log_analytics_workspace_name   = var.log_analytics_workspace_name
  log_analytics_retention_days   = var.log_analytics_retention_days
  application_insights_name      = var.application_insights_name
  common_tags                    = var.common_tags
}

# Database Module (depends on Monitoring)
module "database" {
  source = "./modules/database"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  create_database              = var.create_database
  primary_server_name          = var.primary_server_name
  administrator_login          = var.administrator_login
  postgresql_version           = var.postgresql_version
  primary_sku_name             = var.primary_sku_name
  primary_storage_mb           = var.primary_storage_mb
  create_read_replica          = var.create_read_replica
  replica_server_name          = var.replica_server_name
  replica_location             = var.replica_location
  database_name                = var.database_name
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  enable_high_availability     = var.enable_high_availability
  high_availability_mode       = var.high_availability_mode
  maintenance_window_enabled   = var.maintenance_window_enabled
  maintenance_day_of_week      = var.maintenance_day_of_week
  maintenance_start_hour       = var.maintenance_start_hour
  data_subnet_id               = module.networking.data_subnet_id
  vnet_id                      = module.networking.vnet_id
  availability_zones           = var.availability_zones
  enable_diagnostics           = var.create_log_analytics_workspace
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_id
  diagnostic_setting_name      = "${var.primary_server_name}-diagnostics"
  common_tags                  = var.common_tags

  depends_on = [module.monitoring]
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name                     = azurerm_resource_group.main.name
  location                                = azurerm_resource_group.main.location
  create_key_vault                        = var.create_key_vault
  key_vault_name                          = var.key_vault_name
  key_vault_sku_name                      = var.key_vault_sku_name
  purge_protection_enabled                = var.purge_protection_enabled
  soft_delete_retention_days              = var.soft_delete_retention_days
  key_vault_public_network_access_enabled = var.key_vault_public_network_access_enabled
  common_tags                             = var.common_tags
}

# Container Registry Module
module "container_registry" {
  source = "./modules/container-registry"

  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  create_container_registry         = var.create_container_registry
  acr_name                          = var.acr_name
  acr_sku                           = var.acr_sku
  acr_admin_enabled                 = var.acr_admin_enabled
  acr_public_network_access_enabled = var.acr_public_network_access_enabled
  common_tags                       = var.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  resource_group_name                         = azurerm_resource_group.main.name
  location                                    = azurerm_resource_group.main.location
  presentation_subnet_id                      = module.networking.presentation_subnet_id
  application_subnet_id                       = module.networking.application_subnet_id
  bastion_subnet_id                           = module.networking.bastion_subnet_id
  create_bastion                              = var.create_bastion_subnet
  create_presentation_vmss                    = var.create_presentation_vmss
  presentation_vmss_name                      = var.presentation_vmss_name
  presentation_os_type                        = var.presentation_os_type
  presentation_vm_sku                         = var.presentation_vm_sku
  presentation_instance_count                 = var.presentation_instance_count
  presentation_min_instances                  = var.presentation_min_instances
  presentation_max_instances                  = var.presentation_max_instances
  presentation_os_disk_type                   = var.presentation_os_disk_type
  presentation_os_disk_size_gb                = var.presentation_os_disk_size_gb
  create_application_vmss                     = var.create_application_vmss
  application_vmss_name                       = var.application_vmss_name
  application_os_type                         = var.application_os_type
  application_vm_sku                          = var.application_vm_sku
  application_instance_count                  = var.application_instance_count
  application_min_instances                   = var.application_min_instances
  application_max_instances                   = var.application_max_instances
  application_os_disk_type                    = var.application_os_disk_type
  application_os_disk_size_gb                 = var.application_os_disk_size_gb
  enable_autoscaling                          = var.enable_autoscaling
  presentation_scale_out_cpu_threshold        = var.presentation_scale_out_cpu_threshold
  presentation_scale_in_cpu_threshold         = var.presentation_scale_in_cpu_threshold
  application_scale_out_cpu_threshold         = var.application_scale_out_cpu_threshold
  application_scale_in_cpu_threshold          = var.application_scale_in_cpu_threshold
  admin_username                              = var.admin_username
  ssh_public_key                              = var.ssh_public_key
  internal_lb_backend_address_pool_id         = module.load_balancing.internal_lb_backend_address_pool_id
  application_gateway_backend_address_pool_id = module.load_balancing.application_gateway_backend_address_pool_id
  backend_deployment_group_name               = var.backend_deployment_group_name
  frontend_deployment_group_name              = var.frontend_deployment_group_name
  backend_agent_name_prefix                   = var.backend_agent_name_prefix
  frontend_agent_name_prefix                  = var.frontend_agent_name_prefix
  backend_environment_tags                    = var.backend_environment_tags
  frontend_environment_tags                   = var.frontend_environment_tags
  availability_zones                          = var.availability_zones
  devops_url                                  = var.devops_url
  devops_pat                                  = var.devops_pat
  frontend_agent_pool_name                    = var.frontend_agent_pool_name
  backend_agent_pool_name                     = var.backend_agent_pool_name
  storage_account_name                        = module.remote_state.storage_account_name
  storage_account_connection_string           = module.remote_state.storage_account_connection_string
  common_tags                                 = var.common_tags

  # Ensure agent pools are created before VM extensions try to register agents
  depends_on = [module.azure_devops, module.remote_state]
}

# AI Services Module
module "ai_services" {
  source = "./modules/ai-services"

  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  create_ai_services              = var.create_ai_services
  ai_project_name                 = var.ai_project_name
  enable_openai                   = var.enable_openai
  enable_openai_deployments       = var.enable_openai_deployments
  enable_document_intelligence    = var.enable_document_intelligence
  openai_location                 = var.openai_location
  openai_sku                      = var.openai_sku
  document_intelligence_sku       = var.document_intelligence_sku
  ai_search_sku                   = var.ai_search_sku
  ai_search_public_access_enabled = var.ai_search_public_access_enabled
  ai_search_index_name            = var.ai_search_index_name
  common_tags                     = var.common_tags
}

# Local values for database connection string with URL-encoded password
locals {
  database_connection_string = var.create_database && module.database.primary_server_fqdn != null ? (
    "postgresql+asyncpg://${module.database.administrator_login}:${urlencode(module.database.admin_password)}@${module.database.primary_server_fqdn}:5432/${module.database.database_name}"
  ) : null
}

# Azure DevOps Module
module "azure_devops" {
  source = "./modules/azure-devops"

  resource_group_name                              = azurerm_resource_group.main.name
  resource_group_id                                = azurerm_resource_group.main.id
  location                                         = azurerm_resource_group.main.location
  create_azure_devops                              = var.create_azure_devops
  devops_url                                       = var.devops_url
  devops_pat                                       = var.devops_pat
  devops_use_external_repository                   = var.devops_use_external_repository
  devops_external_repository_url                   = var.devops_external_repository_url
  devops_github_personal_access_token              = var.devops_github_personal_access_token
  devops_github_service_connection_name            = var.devops_github_service_connection_name
  devops_external_repository_service_connection_id = var.devops_external_repository_service_connection_id
  enable_backend_pipeline                          = var.enable_backend_pipeline
  enable_frontend_pipeline                         = var.enable_frontend_pipeline
  backend_deployment_group_name                    = var.backend_deployment_group_name
  frontend_deployment_group_name                   = var.frontend_deployment_group_name
  backend_agent_name_prefix                        = var.backend_agent_name_prefix
  frontend_agent_name_prefix                       = var.frontend_agent_name_prefix
  backend_environment_tags                         = var.backend_environment_tags
  frontend_environment_tags                        = var.frontend_environment_tags
  create_container_registry                        = var.create_container_registry
  acr_name                                         = module.container_registry.acr_name
  acr_id                                           = module.container_registry.acr_id
  acr_admin_password                               = module.container_registry.acr_admin_password
  acr_login_server                                 = module.container_registry.acr_login_server
  openai_api_key                                   = module.ai_services.openai_primary_key
  openai_endpoint                                  = module.ai_services.openai_endpoint
  ai_search_endpoint                               = module.ai_services.ai_search_endpoint
  ai_search_admin_key                              = module.ai_services.ai_search_admin_key
  database_url                                     = local.database_connection_string
  storage_connection_string                        = module.ai_services.storage_account_connection_string
  nextauth_secret                                  = null # Will be set manually
  ssh_public_key                                   = var.ssh_public_key
  common_tags                                      = var.common_tags
  frontend_agent_pool_name                         = var.frontend_agent_pool_name
  backend_agent_pool_name                          = var.backend_agent_pool_name
  internal_lb_private_ip                           = module.load_balancing.internal_lb_private_ip
  internal_lb_backend_port                         = var.internal_lb_backend_port
  internal_lb_frontend_port                        = var.internal_lb_frontend_port
  application_gateway_public_ip                    = module.load_balancing.application_gateway_public_ip_address

  depends_on = [module.container_registry, module.ai_services, module.load_balancing]
}

