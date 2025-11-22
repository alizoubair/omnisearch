variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = ""
}

variable "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  type        = string
  default     = ""
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "create_container_registry" {
  description = "Whether to create the Azure Container Registry"
  type        = bool
  default     = false
}

variable "acr_id" {
  description = "ID of the Azure Container Registry"
  type        = string
  default     = null
}


variable "acr_admin_password" {
  description = "Admin password for ACR"
  type        = string
  sensitive   = true
  default     = null
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = null
}

variable "openai_endpoint" {
  description = "OpenAI endpoint"
  type        = string
  default     = null
}

variable "ai_search_endpoint" {
  description = "AI Search endpoint"
  type        = string
  default     = null
}

variable "ai_search_admin_key" {
  description = "AI Search admin key"
  type        = string
  sensitive   = true
  default     = null
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
  default     = null
}

variable "storage_connection_string" {
  description = "Storage account connection string"
  type        = string
  sensitive   = true
  default     = null
}

variable "nextauth_secret" {
  description = "NextAuth secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  sensitive   = true
}

variable "internal_lb_private_ip" {
  description = "Private IP address of the internal load balancer (for API endpoint)"
  type        = string
  default     = null
}

variable "internal_lb_backend_port" {
  description = "Backend port of the internal load balancer (for API endpoint)"
  type        = number
  default     = 8000
}

variable "internal_lb_frontend_port" {
  description = "Frontend port of the internal load balancer (for API endpoint)"
  type        = number
  default     = 80
}

variable "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway (for NEXTAUTH_URL)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


