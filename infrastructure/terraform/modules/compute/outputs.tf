output "presentation_vmss_id" {
  description = "ID of the presentation tier VM scale set"
  value       = var.create_presentation_vmss ? azurerm_linux_virtual_machine_scale_set.presentation[0].id : null
}

output "application_vmss_id" {
  description = "ID of the application tier VM scale set"
  value       = var.create_application_vmss ? azurerm_linux_virtual_machine_scale_set.application[0].id : null
}

output "bastion_host_id" {
  description = "ID of the Azure Bastion host"
  value       = var.create_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion host"
  value       = var.create_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

