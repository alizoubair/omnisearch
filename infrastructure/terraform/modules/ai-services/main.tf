# Cognitive Services Account for OpenAI
resource "azurerm_cognitive_account" "openai" {
  count                 = var.create_ai_services && var.enable_openai ? 1 : 0
  name                  = "${var.ai_project_name}-openai-v2"
  location              = var.openai_location
  resource_group_name   = var.resource_group_name
  kind                  = "OpenAI"
  sku_name              = var.openai_sku
  custom_subdomain_name = "${var.ai_project_name}-openai-v2"
  tags                  = var.common_tags
}

# Cognitive Services Account for Document Intelligence
resource "azurerm_cognitive_account" "document_intelligence" {
  count                 = var.create_ai_services && var.enable_document_intelligence ? 1 : 0
  name                  = "${var.ai_project_name}-docintel"
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "FormRecognizer"
  sku_name              = var.document_intelligence_sku
  custom_subdomain_name = "${var.ai_project_name}-docintel"
  tags                  = var.common_tags
}

# Azure AI Search (formerly Azure Cognitive Search)
resource "azurerm_search_service" "ai_search" {
  count               = var.create_ai_services ? 1 : 0
  name                = "${var.ai_project_name}-search-dev"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.ai_search_sku
  public_network_access_enabled = var.ai_search_public_access_enabled
  tags                = var.common_tags
}

# OpenAI Deployments
# Note: Deployments require quota approval. Set enable_openai_deployments=false if quota is not available
resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  count                = var.create_ai_services && var.enable_openai && var.enable_openai_deployments ? 1 : 0
  name                 = "gpt-4o-mini-dev"
  cognitive_account_id = azurerm_cognitive_account.openai[0].id
  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }
  sku {
    name = "Standard"
    capacity = 1
  }
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

resource "azurerm_cognitive_deployment" "text_embedding_ada_002" {
  count                = var.create_ai_services && var.enable_openai && var.enable_openai_deployments ? 1 : 0
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai[0].id
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }
  sku {
    name = "Standard"
    capacity = 1
  }
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

# Storage Account for AI Services
# Note: Using different name to avoid conflict with remote state storage account
resource "azurerm_storage_account" "ai_storage" {
  count                    = var.create_ai_services ? 1 : 0
  name                     = "${replace(var.ai_project_name, "-", "")}aistorage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.common_tags
}

# Storage Container for Documents
resource "azurerm_storage_container" "ai_documents" {
  count                 = var.create_ai_services ? 1 : 0
  name                  = "documents"
  storage_account_name  = azurerm_storage_account.ai_storage[0].name
  container_access_type = "private"
}

