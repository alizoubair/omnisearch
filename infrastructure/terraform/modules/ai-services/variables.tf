variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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
  default     = false
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


