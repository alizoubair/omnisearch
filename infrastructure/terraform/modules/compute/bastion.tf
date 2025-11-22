# Azure Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  count               = var.create_bastion ? 1 : 0
  name                = "pip-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.create_bastion ? 1 : 0
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku              = "Standard"  # Required for Native Client (SSH/RDP via CLI)
  tunneling_enabled = true       # Enable Native Client support for SSH/RDP via Azure CLI

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.common_tags
}

