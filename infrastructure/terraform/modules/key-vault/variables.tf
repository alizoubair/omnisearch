variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

