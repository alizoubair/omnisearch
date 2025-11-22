# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.create_log_analytics_workspace ? 1 : 0
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count               = var.create_log_analytics_workspace ? 1 : 0
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = "web"
  tags                = var.common_tags
}

