# Data source to get storage account details
# Create if either presentation or application VMSS is created
data "azurerm_storage_account" "script_storage" {
  count               = (var.create_presentation_vmss || var.create_application_vmss) && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Storage Container for Scripts
# Create if either presentation or application VMSS is created
resource "azurerm_storage_container" "scripts" {
  count                = (var.create_presentation_vmss || var.create_application_vmss) && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  name                 = "scripts"
  storage_account_id   = data.azurerm_storage_account.script_storage[0].id
  container_access_type = "private"
}

# Upload DevOps Agent Installation Script
# Create if either presentation or application VMSS is created
resource "azurerm_storage_blob" "install_devops_agent" {
  count                  = (var.create_presentation_vmss || var.create_application_vmss) && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  name                   = "install-devops-agent.sh"
  storage_account_name   = var.storage_account_name
  storage_container_name = azurerm_storage_container.scripts[0].name
  type                   = "Block"
  source                 = "${path.root}/../../scripts/install-devops-agent.sh"
  content_md5            = filemd5("${path.root}/../../scripts/install-devops-agent.sh")

  depends_on = [azurerm_storage_container.scripts]
}

# SAS Token for Script Access (valid for 1 year)
# Create if either presentation or application VMSS is created
data "azurerm_storage_account_sas" "script_sas" {
  count             = (var.create_presentation_vmss || var.create_application_vmss) && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  connection_string = var.storage_account_connection_string
  https_only        = true
  start             = timestamp()
  expiry            = timeadd(timestamp(), "8760h") # 1 year

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

