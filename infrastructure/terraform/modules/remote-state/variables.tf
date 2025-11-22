variable "create_remote_state" {
  description = "Whether to create the remote state storage account and container"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


