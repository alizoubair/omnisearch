variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "presentation_subnet_id" {
  description = "ID of the presentation tier subnet"
  type        = string
}

variable "application_subnet_id" {
  description = "ID of the application tier subnet"
  type        = string
}

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

variable "internal_lb_backend_address_pool_id" {
  description = "ID of the internal load balancer backend address pool"
  type        = string
  default     = null
}

variable "application_gateway_backend_address_pool_id" {
  description = "ID of the application gateway backend address pool"
  type        = string
  default     = null
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

variable "devops_url" {
  description = "Azure DevOps organization URL"
  type        = string
  default     = ""
}

variable "devops_pat" {
  description = "Azure DevOps Personal Access Token for agent registration"
  type        = string
  sensitive   = true
  default     = ""
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

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = []
}

variable "bastion_subnet_id" {
  description = "ID of the bastion subnet for Azure Bastion"
  type        = string
  default     = null
}

variable "create_bastion" {
  description = "Whether to create Azure Bastion for SSH access"
  type        = bool
  default     = false
}

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
  default     = "bastion-omnisearch-dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "storage_account_name" {
  description = "Name of the storage account for script storage"
  type        = string
  default     = ""
}

variable "storage_account_connection_string" {
  description = "Connection string for the storage account (for SAS token generation)"
  type        = string
  sensitive   = true
  default     = ""
}

