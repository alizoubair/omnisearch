output "primary_server_id" {
  description = "ID of the primary database server"
  value       = var.create_database ? azurerm_postgresql_flexible_server.primary[0].id : null
}

output "primary_server_fqdn" {
  description = "FQDN of the primary database server"
  value       = var.create_database ? azurerm_postgresql_flexible_server.primary[0].fqdn : null
}

output "database_name" {
  description = "Name of the database"
  value       = var.create_database ? azurerm_postgresql_flexible_server_database.main[0].name : null
}

output "administrator_login" {
  description = "Administrator login for the database"
  value       = var.create_database ? azurerm_postgresql_flexible_server.primary[0].administrator_login : null
  sensitive   = false
}

output "replica_server_id" {
  description = "ID of the replica database server"
  value       = var.create_database && var.create_read_replica ? azurerm_postgresql_flexible_server.replica[0].id : null
}

output "replica_server_fqdn" {
  description = "FQDN of the replica database server"
  value       = var.create_database && var.create_read_replica ? azurerm_postgresql_flexible_server.replica[0].fqdn : null
}

output "admin_password" {
  description = "Administrator password for the database (sensitive)"
  value       = var.create_database ? random_password.admin_password[0].result : null
  sensitive   = true
}

