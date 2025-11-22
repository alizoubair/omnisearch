# Storage Account for Terraform Remote State
resource "azurerm_storage_account" "tfstate" {
  count                    = var.create_remote_state ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  # Enable blob soft delete for state protection
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.common_tags
}

# Storage Container for Terraform State
resource "azurerm_storage_container" "tfstate" {
  count                 = var.create_remote_state ? 1 : 0
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate[0].name
  container_access_type = "private"
}

