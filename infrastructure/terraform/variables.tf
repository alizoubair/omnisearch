# Remote State Configuration
variable "create_remote_state" {
  description = "Set to false after remote state is created to prevent destruction"
  type        = bool
  default     = true
}

variable "remote_state_storage_account_name" {
  description = "Name of the storage account for Terraform remote state"
  type        = string
  default     = "omnisearchaistoragedev"
}

variable "remote_state_container_name" {
  description = "Name of the storage container for Terraform remote state"
  type        = string
  default     = "tfstate"
}

# Common Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking Configuration
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "presentation_subnet_name" {
  description = "Name of the presentation tier subnet"
  type        = string
}

variable "presentation_subnet_prefixes" {
  description = "Address prefixes for the presentation tier subnet"
  type        = list(string)
}

variable "application_subnet_name" {
  description = "Name of the application tier subnet"
  type        = string
}

variable "application_subnet_prefixes" {
  description = "Address prefixes for the application tier subnet"
  type        = list(string)
}

variable "data_subnet_name" {
  description = "Name of the data tier subnet"
  type        = string
}

variable "data_subnet_prefixes" {
  description = "Address prefixes for the data tier subnet"
  type        = list(string)
}

variable "create_bastion_subnet" {
  description = "Whether to create a bastion subnet and Azure Bastion host"
  type        = bool
  default     = false
}

variable "create_app_gateway_subnet" {
  description = "Whether to create an application gateway subnet"
  type        = bool
  default     = true
}

# Application Gateway Configuration
variable "create_application_gateway" {
  description = "Whether to create an application gateway"
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Whether to enable HTTPS listener on application gateway"
  type        = bool
  default     = false
}

variable "application_gateway_name" {
  description = "Name of the application gateway"
  type        = string
}

variable "application_gateway_public_ip_name" {
  description = "Name of the application gateway public IP"
  type        = string
}

variable "application_gateway_sku_name" {
  description = "SKU name for the application gateway (Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_v2)"
  type        = string
  default     = "Standard_Small"
}

variable "application_gateway_sku_tier" {
  description = "SKU tier for the application gateway (Standard, Standard_v2, WAF, WAF_v2)"
  type        = string
  default     = "Standard"
}

variable "application_gateway_capacity" {
  description = "Capacity for the application gateway"
  type        = number
  default     = 1
}

variable "application_gateway_min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 1
}

variable "application_gateway_max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 2
}

variable "enable_app_gateway_autoscaling" {
  description = "Whether to enable autoscaling for application gateway"
  type        = bool
  default     = false
}

variable "application_gateway_backend_port" {
  description = "Backend port for application gateway"
  type        = number
  default     = 3000
}

variable "application_gateway_probe_path" {
  description = "Health probe path for application gateway"
  type        = string
  default     = "/"
}

variable "application_gateway_backend_https_port" {
  description = "Backend HTTPS port for application gateway"
  type        = number
  default     = 3000
}

# NAT Gateway Configuration
variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = true
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT gateway"
  type        = list(string)
  default     = []
}

variable "associate_nat_with_application" {
  description = "Whether to associate NAT gateway with application subnet"
  type        = bool
  default     = true
}

# Availability Zones Configuration
variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = []
}

# Load Balancer Configuration
variable "create_internal_lb" {
  description = "Whether to create an internal load balancer"
  type        = bool
  default     = true
}

variable "internal_lb_name" {
  description = "Name of the internal load balancer"
  type        = string
}

variable "internal_lb_private_ip" {
  description = "Private IP address for the internal load balancer"
  type        = string
}

variable "internal_lb_probe_path" {
  description = "Health probe path for the internal load balancer"
  type        = string
  default     = "/api/health"
}

variable "internal_lb_frontend_port" {
  description = "Frontend port for the internal load balancer"
  type        = number
  default     = 80
}

variable "internal_lb_backend_port" {
  description = "Backend port for the internal load balancer"
  type        = number
  default     = 8000
}

variable "internal_lb_probe_port" {
  description = "Health probe port for the internal load balancer"
  type        = number
  default     = 8000
}

variable "enable_internal_https_rule" {
  description = "Whether to enable HTTPS rule for internal load balancer"
  type        = bool
  default     = false
}

# NAT Pool Configuration
variable "enable_nat_pool" {
  description = "Whether to enable NAT pool for SSH access"
  type        = bool
  default     = true
}

variable "nat_pool_frontend_port_start" {
  description = "Start port for NAT pool"
  type        = number
  default     = 50000
}

variable "nat_pool_frontend_port_end" {
  description = "End port for NAT pool"
  type        = number
  default     = 50010
}

variable "nat_pool_backend_port" {
  description = "Backend port for NAT pool"
  type        = number
  default     = 22
}

# Authentication Configuration
variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VMs"
  type        = string
  sensitive   = true
}

# Presentation Tier Configuration
variable "create_presentation_vmss" {
  description = "Whether to create presentation tier VM scale set"
  type        = bool
  default     = true
}

variable "presentation_vmss_name" {
  description = "Name of the presentation tier VM scale set"
  type        = string
}

variable "presentation_os_type" {
  description = "OS type for presentation tier VMs"
  type        = string
  default     = "Linux"
}

variable "presentation_vm_sku" {
  description = "VM SKU for presentation tier"
  type        = string
  default     = "Standard_B1s"
}

variable "presentation_instance_count" {
  description = "Instance count for presentation tier VM scale set"
  type        = number
  default     = 1
}

variable "presentation_min_instances" {
  description = "Minimum instances for presentation tier autoscaling"
  type        = number
  default     = 1
}

variable "presentation_max_instances" {
  description = "Maximum instances for presentation tier autoscaling"
  type        = number
  default     = 3
}

variable "presentation_os_disk_type" {
  description = "OS disk type for presentation tier VMs"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "presentation_os_disk_size_gb" {
  description = "OS disk size in GB for presentation tier VMs"
  type        = number
  default     = 30
}

# Application Tier Configuration
variable "create_application_vmss" {
  description = "Whether to create application tier VM scale set"
  type        = bool
  default     = true
}

variable "application_vmss_name" {
  description = "Name of the application tier VM scale set"
  type        = string
}

variable "application_os_type" {
  description = "OS type for application tier VMs"
  type        = string
  default     = "Linux"
}

variable "application_vm_sku" {
  description = "VM SKU for application tier"
  type        = string
  default     = "Standard_B2s"
}

variable "application_instance_count" {
  description = "Instance count for application tier VM scale set"
  type        = number
  default     = 1
}

variable "application_min_instances" {
  description = "Minimum instances for application tier autoscaling"
  type        = number
  default     = 1
}

variable "application_max_instances" {
  description = "Maximum instances for application tier autoscaling"
  type        = number
  default     = 5
}

variable "application_os_disk_type" {
  description = "OS disk type for application tier VMs"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "application_os_disk_size_gb" {
  description = "OS disk size in GB for application tier VMs"
  type        = number
  default     = 30
}

# Auto-scaling Configuration
variable "enable_autoscaling" {
  description = "Whether to enable autoscaling"
  type        = bool
  default     = true
}

variable "presentation_scale_out_cpu_threshold" {
  description = "CPU threshold for scaling out presentation tier"
  type        = number
  default     = 80
}

variable "presentation_scale_in_cpu_threshold" {
  description = "CPU threshold for scaling in presentation tier"
  type        = number
  default     = 20
}

variable "application_scale_out_cpu_threshold" {
  description = "CPU threshold for scaling out application tier"
  type        = number
  default     = 75
}

variable "application_scale_in_cpu_threshold" {
  description = "CPU threshold for scaling in application tier"
  type        = number
  default     = 25
}

variable "public_domain_name" {
  description = "Public domain name"
  type        = string
  default     = ""
}

# Key Vault Configuration
variable "create_key_vault" {
  description = "Whether to create a key vault"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Name of the key vault"
  type        = string
}

variable "key_vault_sku_name" {
  description = "SKU name for the key vault"
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  description = "Whether to enable purge protection on key vault"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days for key vault"
  type        = number
  default     = 7
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether to enable public network access on key vault"
  type        = bool
  default     = false
}

# Database Configuration
variable "create_database" {
  description = "Whether to create a database"
  type        = bool
  default     = true
}

variable "primary_server_name" {
  description = "Name of the primary database server"
  type        = string
}

variable "administrator_login" {
  description = "Administrator login for the database"
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"
}

variable "primary_sku_name" {
  description = "SKU name for the primary database server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "primary_storage_mb" {
  description = "Storage in MB for the primary database server"
  type        = number
  default     = 32768
}

variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

variable "replica_server_name" {
  description = "Name of the replica database server"
  type        = string
  default     = ""
}

variable "replica_location" {
  description = "Location for the replica database server"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "backup_retention_days" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Whether to enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "enable_high_availability" {
  description = "Whether to enable high availability"
  type        = bool
  default     = false
}

variable "high_availability_mode" {
  description = "High availability mode"
  type        = string
  default     = "ZoneRedundant"
}

variable "maintenance_window_enabled" {
  description = "Whether to enable maintenance window"
  type        = bool
  default     = true
}

variable "maintenance_day_of_week" {
  description = "Day of week for maintenance window (0=Sunday, 6=Saturday)"
  type        = number
  default     = 6
}

variable "maintenance_start_hour" {
  description = "Start hour for maintenance window"
  type        = number
  default     = 22
}

# Monitoring Configuration
variable "create_log_analytics_workspace" {
  description = "Whether to create a Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "log_analytics_retention_days" {
  description = "Retention days for Log Analytics workspace"
  type        = number
  default     = 30
}

variable "application_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
}

# AI Services Configuration
variable "create_ai_services" {
  description = "Whether to create AI services"
  type        = bool
  default     = true
}

variable "ai_project_name" {
  description = "Name of the AI project"
  type        = string
  default     = "omnisearch"
}

variable "enable_openai" {
  description = "Whether to enable OpenAI"
  type        = bool
  default     = true
}

variable "enable_openai_deployments" {
  description = "Whether to create OpenAI deployments (requires quota approval)"
  type        = bool
  default     = true
}

variable "enable_document_intelligence" {
  description = "Whether to enable Document Intelligence"
  type        = bool
  default     = true
}

variable "openai_location" {
  description = "Location for OpenAI service"
  type        = string
  default     = "East US 2"
}

variable "openai_sku" {
  description = "SKU for OpenAI service"
  type        = string
  default     = "S0"
}

variable "document_intelligence_sku" {
  description = "SKU for Document Intelligence service"
  type        = string
  default     = "F0"
}

variable "ai_search_sku" {
  description = "SKU for AI Search service"
  type        = string
  default     = "basic"
}

variable "ai_search_public_access_enabled" {
  description = "Whether to enable public access on AI Search"
  type        = bool
  default     = true
}

variable "ai_search_index_name" {
  description = "Name of the AI Search index"
  type        = string
  default     = "documents"
}

# Container Registry Configuration
variable "create_container_registry" {
  description = "Whether to create a container registry"
  type        = bool
  default     = true
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "acr_admin_enabled" {
  description = "Whether to enable admin user on ACR"
  type        = bool
  default     = true
}

variable "acr_public_network_access_enabled" {
  description = "Whether to enable public network access on ACR"
  type        = bool
  default     = true
}

# Azure DevOps Configuration
variable "create_azure_devops" {
  description = "Whether to create Azure DevOps resources"
  type        = bool
  default     = true
}

variable "devops_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "devops_pat" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  sensitive   = true
}

variable "devops_use_external_repository" {
  description = "Whether to use external repository (GitHub)"
  type        = bool
  default     = false
}

variable "devops_external_repository_url" {
  description = "External repository URL (format: owner/repo)"
  type        = string
  default     = ""
}

variable "devops_github_personal_access_token" {
  description = "GitHub Personal Access Token for service connection"
  type        = string
  sensitive   = true
  default     = ""
}

variable "devops_github_service_connection_name" {
  description = "Name of the GitHub service connection (optional)"
  type        = string
  default     = ""
}

variable "devops_external_repository_service_connection_id" {
  description = "Existing GitHub service connection ID (if not using auto-creation)"
  type        = string
  default     = ""
}

variable "enable_backend_pipeline" {
  description = "Whether to enable backend CI/CD pipeline"
  type        = bool
  default     = true
}

variable "enable_frontend_pipeline" {
  description = "Whether to enable frontend CI/CD pipeline"
  type        = bool
  default     = true
}

variable "backend_deployment_group_name" {
  description = "Backend deployment group name"
  type        = string
  default     = "backend-vms"
}

variable "frontend_deployment_group_name" {
  description = "Frontend deployment group name"
  type        = string
  default     = "frontend-vms"
}

variable "backend_agent_name_prefix" {
  description = "Backend agent name prefix"
  type        = string
  default     = "backend-agent"
}

variable "frontend_agent_name_prefix" {
  description = "Frontend agent name prefix"
  type        = string
  default     = "frontend-agent"
}

variable "frontend_agent_pool_name" {
  description = "Frontend agent pool name"
  type        = string
  default     = "frontend-vms"
}

variable "backend_agent_pool_name" {
  description = "Backend agent pool name"
  type        = string
  default     = "backend-vms"
}

variable "backend_environment_tags" {
  description = "Backend environment tags"
  type        = string
  default     = "backend,api"
}

variable "frontend_environment_tags" {
  description = "Frontend environment tags"
  type        = string
  default     = "frontend,web"
}

# Azure Managed DevOps Pool Configuration
variable "create_managed_devops_pool_subnet" {
  description = "Whether to create a subnet for Azure Managed DevOps Pool"
  type        = bool
  default     = false
}

variable "enable_managed_devops_pool" {
  description = "Whether to enable Azure Managed DevOps Pool"
  type        = bool
  default     = false
}

variable "managed_pool_name" {
  description = "Name for the Azure Managed DevOps Pool"
  type        = string
  default     = ""
}

variable "managed_pool_maximum_concurrency" {
  description = "Maximum number of concurrent agents in the managed pool"
  type        = number
  default     = 4
}

