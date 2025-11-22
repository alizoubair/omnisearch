terraform {
  backend "azurerm" {
    resource_group_name  = "rg-omnisearch-dev"
    storage_account_name = "omnisearchaistoragedev"
    container_name       = "tfstate"
    key                  = "omnisearch.terraform.tfstate"
  }
}


