output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.create_remote_state ? azurerm_storage_account.tfstate[0].name : null
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = var.create_remote_state ? azurerm_storage_account.tfstate[0].id : null
}

output "container_name" {
  description = "Name of the storage container"
  value       = var.create_remote_state ? azurerm_storage_container.tfstate[0].name : null
}

output "primary_access_key" {
  description = "Primary access key for the storage account (sensitive)"
  value       = var.create_remote_state ? azurerm_storage_account.tfstate[0].primary_access_key : null
  sensitive   = true
}

output "storage_account_endpoint" {
  description = "Endpoint for the storage account"
  value       = var.create_remote_state ? azurerm_storage_account.tfstate[0].primary_blob_endpoint : null
}

output "storage_account_connection_string" {
  description = "Connection string for the storage account"
  value       = var.create_remote_state ? azurerm_storage_account.tfstate[0].primary_connection_string : null
  sensitive   = true
}


