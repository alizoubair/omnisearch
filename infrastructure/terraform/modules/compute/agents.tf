# Azure DevOps Agent Extension for Presentation Tier VMSS
resource "azurerm_virtual_machine_scale_set_extension" "devops_agent_presentation" {
  count                        = var.create_presentation_vmss && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  name                         = "devops-agent-extension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.presentation[0].id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"

  settings = jsonencode({
    fileUris = [
      "https://${var.storage_account_name}.blob.core.windows.net/${azurerm_storage_container.scripts[0].name}/${azurerm_storage_blob.install_devops_agent[0].name}${data.azurerm_storage_account_sas.script_sas[0].sas}"
    ]
  })

  protected_settings = jsonencode({
    commandToExecute = "chmod +x install-devops-agent.sh && bash install-devops-agent.sh '${var.frontend_agent_pool_name != "" ? var.frontend_agent_pool_name : "frontend-vms"}' '${var.devops_url}' '${var.devops_pat}' '${var.frontend_agent_name_prefix != "" ? var.frontend_agent_name_prefix : "frontend-agent"}'"
  })

  # Force update to trigger re-run when script changes
  # Use file MD5 hash as force_update_tag (changes when script changes)
  # Truncate to 50 chars max (Azure limit)
  force_update_tag = substr(filemd5("${path.root}/../../scripts/install-devops-agent.sh"), 0, 50)

  depends_on = [
    azurerm_storage_blob.install_devops_agent,
    data.azurerm_storage_account_sas.script_sas
  ]
}

# Azure DevOps Agent Extension for Application Tier VMSS
resource "azurerm_virtual_machine_scale_set_extension" "devops_agent_application" {
  count                        = var.create_application_vmss && var.devops_url != "" && var.devops_pat != "" && var.storage_account_name != "" ? 1 : 0
  name                         = "devops-agent-extension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.application[0].id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"

  settings = jsonencode({
    fileUris = [
      "https://${var.storage_account_name}.blob.core.windows.net/${azurerm_storage_container.scripts[0].name}/${azurerm_storage_blob.install_devops_agent[0].name}${data.azurerm_storage_account_sas.script_sas[0].sas}"
    ]
  })

  protected_settings = jsonencode({
    commandToExecute = "chmod +x install-devops-agent.sh && bash install-devops-agent.sh '${var.backend_agent_pool_name != "" ? var.backend_agent_pool_name : "backend-vms"}' '${var.devops_url}' '${var.devops_pat}' '${var.backend_agent_name_prefix != "" ? var.backend_agent_name_prefix : "backend-agent"}'"
  })

  # Force update to trigger re-run when script changes
  # Use file MD5 hash as force_update_tag (changes when script changes)
  # Truncate to 50 chars max (Azure limit)
  force_update_tag = substr(filemd5("${path.root}/../../scripts/install-devops-agent.sh"), 0, 50)

  depends_on = [
    azurerm_storage_blob.install_devops_agent,
    data.azurerm_storage_account_sas.script_sas
  ]
}