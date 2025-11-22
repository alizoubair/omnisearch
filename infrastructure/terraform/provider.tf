provider "azurerm" {
  subscription_id = "0028cd3a-1a40-471e-a192-fc9a1882813a"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuredevops" {
  org_service_url       = var.devops_url
  personal_access_token = var.devops_pat
}

provider "azuread" {
  # Azure AD provider configuration
  # Uses default authentication (Azure CLI, Environment Variables, or Managed Identity)
}

