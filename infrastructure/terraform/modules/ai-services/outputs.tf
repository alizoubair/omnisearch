output "openai_endpoint" {
  description = "Endpoint of the OpenAI service"
  value       = var.create_ai_services && var.enable_openai ? azurerm_cognitive_account.openai[0].endpoint : null
}

output "openai_primary_key" {
  description = "Primary key of the OpenAI service"
  value       = var.create_ai_services && var.enable_openai ? azurerm_cognitive_account.openai[0].primary_access_key : null
  sensitive   = true
}

output "document_intelligence_endpoint" {
  description = "Endpoint of the Document Intelligence service"
  value       = var.create_ai_services && var.enable_document_intelligence ? azurerm_cognitive_account.document_intelligence[0].endpoint : null
}

output "document_intelligence_primary_key" {
  description = "Primary key of the Document Intelligence service"
  value       = var.create_ai_services && var.enable_document_intelligence ? azurerm_cognitive_account.document_intelligence[0].primary_access_key : null
  sensitive   = true
}

output "ai_search_endpoint" {
  description = "Endpoint of the AI Search service"
  value       = var.create_ai_services ? "https://${azurerm_search_service.ai_search[0].name}.search.windows.net" : null
}

output "ai_search_admin_key" {
  description = "Admin key of the AI Search service"
  value       = var.create_ai_services ? azurerm_search_service.ai_search[0].primary_key : null
  sensitive   = true
}

output "ai_search_query_key" {
  description = "Query key of the AI Search service"
  value       = var.create_ai_services ? azurerm_search_service.ai_search[0].query_keys[0].key : null
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the storage account for AI services"
  value       = var.create_ai_services ? azurerm_storage_account.ai_storage[0].name : null
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  value       = var.create_ai_services ? azurerm_storage_account.ai_storage[0].primary_access_key : null
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string of the storage account"
  value       = var.create_ai_services ? azurerm_storage_account.ai_storage[0].primary_connection_string : null
  sensitive   = true
}

