variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

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

variable "data_subnet_id" {
  description = "ID of the data tier subnet"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = []
}

variable "enable_diagnostics" {
  description = "Whether to enable diagnostic settings (requires log_analytics_workspace_id)"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

variable "diagnostic_setting_name" {
  description = "Name of the diagnostic setting for the database"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

