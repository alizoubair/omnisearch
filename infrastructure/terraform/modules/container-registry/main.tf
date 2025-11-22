# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  count                   = var.create_container_registry ? 1 : 0
  name                    = var.acr_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku                     = var.acr_sku
  admin_enabled           = var.acr_admin_enabled
  public_network_access_enabled = var.acr_public_network_access_enabled
  tags                    = var.common_tags
}

# Get current client config for role assignments
data "azurerm_client_config" "current" {}

# Role Assignment: ACR Pull for VMs (managed identity)
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.create_container_registry ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role Assignment: ACR Push for VMs (managed identity)
resource "azurerm_role_assignment" "acr_push" {
  count                = var.create_container_registry ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}