variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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
  description = "Whether to create a bastion subnet"
  type        = bool
  default     = false
}

variable "create_app_gateway_subnet" {
  description = "Whether to create an application gateway subnet"
  type        = bool
  default     = true
}

variable "create_managed_devops_pool_subnet" {
  description = "Whether to create a subnet for Azure Managed DevOps Pool"
  type        = bool
  default     = false
}

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

variable "associate_nat_with_presentation" {
  description = "Whether to associate NAT gateway with presentation subnet"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

