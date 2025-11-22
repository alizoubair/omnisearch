variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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

variable "vm_scale_set_principal_id" {
  description = "Principal ID of VM Scale Set managed identity (if using managed identity)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

