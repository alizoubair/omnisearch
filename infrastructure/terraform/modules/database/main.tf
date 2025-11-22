# Random password for database administrator
resource "random_password" "admin_password" {
  count   = var.create_database ? 1 : 0
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in Key Vault (if Key Vault exists)
# This will be handled by the key-vault module

# PostgreSQL Flexible Server - Primary
resource "azurerm_postgresql_flexible_server" "primary" {
  count                  = var.create_database ? 1 : 0
  name                   = var.primary_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgresql_version
  # Removed delegated_subnet_id - using public network access only (no VNet integration)
  public_network_access_enabled = true  # Using public network access
  administrator_login         = var.administrator_login
  administrator_password      = random_password.admin_password[0].result
  zone                        = length(var.availability_zones) > 0 ? var.availability_zones[0] : null

  storage_mb = var.primary_storage_mb

  sku_name = var.primary_sku_name

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = length(var.availability_zones) > 1 ? var.availability_zones[1] : null
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window_enabled ? [1] : []
    content {
      day_of_week  = var.maintenance_day_of_week
      start_hour   = var.maintenance_start_hour
      start_minute = 0
    }
  }

  tags = var.common_tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.create_database ? 1 : 0
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.primary[0].id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rules
# Allow connections from Azure services (0.0.0.0 means allow all Azure IPs)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  count            = var.create_database ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.primary[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Server Configuration
resource "azurerm_postgresql_flexible_server_configuration" "primary" {
  count     = var.create_database ? 1 : 0
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.primary[0].id
  value     = "pg_stat_statements"
}

# Monitor Diagnostic Setting for Database
resource "azurerm_monitor_diagnostic_setting" "primary" {
  count                      = var.create_database && var.enable_diagnostics ? 1 : 0
  name                       = var.diagnostic_setting_name != null ? var.diagnostic_setting_name : "${var.primary_server_name}-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.primary[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# PostgreSQL Read Replica (optional)
resource "azurerm_postgresql_flexible_server" "replica" {
  count              = var.create_database && var.create_read_replica ? 1 : 0
  name               = var.replica_server_name
  resource_group_name = var.resource_group_name
  location           = var.replica_location != "" ? var.replica_location : var.location
  version            = var.postgresql_version
  create_mode        = "Replica"
  source_server_id   = azurerm_postgresql_flexible_server.primary[0].id

  tags = var.common_tags
}

