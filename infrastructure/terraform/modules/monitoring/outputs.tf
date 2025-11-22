output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].name : null
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = var.create_log_analytics_workspace ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.create_log_analytics_workspace ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.create_log_analytics_workspace ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

