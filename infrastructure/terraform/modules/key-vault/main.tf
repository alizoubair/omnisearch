# Get current Azure client config
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  count                      = var.create_key_vault ? 1 : 0
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku_name
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  tags                       = var.common_tags

  dynamic "network_acls" {
    for_each = var.key_vault_public_network_access_enabled ? [] : [1]
    content {
      default_action = "Deny"
      bypass         = "AzureServices"
    }
  }
}
