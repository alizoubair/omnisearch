variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

