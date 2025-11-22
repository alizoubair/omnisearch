# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = ["168.63.129.16"]
  tags                = var.common_tags
}

# Presentation Tier Subnet (Web/Frontend)
resource "azurerm_subnet" "presentation" {
  name                 = var.presentation_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.presentation_subnet_prefixes
}

# Application Tier Subnet (API/Backend)
resource "azurerm_subnet" "application" {
  name                 = var.application_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.application_subnet_prefixes
}

# Data Tier Subnet (Database)
resource "azurerm_subnet" "data" {
  name                 = var.data_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.data_subnet_prefixes

  delegation {
    name = "database-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Application Gateway Subnet (optional)
resource "azurerm_subnet" "app_gateway" {
  count                = var.create_app_gateway_subnet ? 1 : 0
  name                 = "snet-appgateway"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 10)]
}

# Bastion Subnet
resource "azurerm_subnet" "bastion" {
  count                = var.create_bastion_subnet ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 11)]
}

# Managed DevOps Pool Subnet (with delegation for Microsoft.DevOpsInfrastructure/pools)
resource "azurerm_subnet" "managed_devops_pool" {
  count                = var.create_managed_devops_pool_subnet ? 1 : 0
  name                 = "snet-managed-devops-pool"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 12)]

  delegation {
    name = "devops-infrastructure-delegation"

    service_delegation {
      name = "Microsoft.DevOpsInfrastructure/pools"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "presentation" {
  name                = "nsg-presentation"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_network_security_group" "application" {
  name                = "nsg-application"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

# NSG Rules for Presentation Tier (allow HTTP/HTTPS from Application Gateway)
resource "azurerm_network_security_rule" "presentation_http" {
  name                        = "AllowHTTP"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

resource "azurerm_network_security_rule" "presentation_https" {
  name                        = "AllowHTTPS"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

resource "azurerm_network_security_rule" "presentation_app_port" {
  name                        = "AllowAppPort"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

# Outbound NSG Rules for Presentation Tier (allow DNS and HTTPS outbound)
resource "azurerm_network_security_rule" "presentation_outbound_dns_udp" {
  name                        = "AllowOutboundDNS"
  priority                    = 2000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

resource "azurerm_network_security_rule" "presentation_outbound_dns_tcp" {
  name                        = "AllowOutboundDNS_TCP"
  priority                    = 2001  # higher than UDP
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

resource "azurerm_network_security_rule" "presentation_outbound_https" {
  name                        = "AllowOutboundHTTPS"
  priority                    = 2002
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

# Allow all outbound internet traffic via NAT Gateway
resource "azurerm_network_security_rule" "presentation_outbound_all" {
  name                        = "AllowOutboundInternet"
  priority                    = 2003
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.presentation.name
}

# NSG Rules for Application Tier (allow API traffic from Load Balancer)
resource "azurerm_network_security_rule" "application_api" {
  name                        = "AllowAPI"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.application.name
}

# Outbound NSG Rules for Application Tier (allow DNS and HTTPS outbound)
resource "azurerm_network_security_rule" "application_outbound_dns" {
  name                        = "AllowOutboundDNS"
  priority                    = 2000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.application.name
}

resource "azurerm_network_security_rule" "application_outbound_https" {
  name                        = "AllowOutboundHTTPS"
  priority                    = 2001
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.application.name
}

# Allow all outbound internet traffic via NAT Gateway
resource "azurerm_network_security_rule" "application_outbound_all" {
  name                        = "AllowOutboundInternet"
  priority                    = 2002
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.application.name
}

# NSG Rules for Data Tier (allow PostgreSQL from Application Tier)
resource "azurerm_network_security_rule" "data_postgres" {
  name                        = "AllowPostgreSQL"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "presentation" {
  subnet_id                 = azurerm_subnet.presentation.id
  network_security_group_id = azurerm_network_security_group.presentation.id
}

resource "azurerm_subnet_network_security_group_association" "application" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.application.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# NAT Gateway Public IP
resource "azurerm_public_ip" "nat_gateway" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "pip-nat-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.nat_gateway_zones
  tags                = var.common_tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count                   = var.create_nat_gateway ? 1 : 0
  name                    = "nat-gateway"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  zones                   = var.nat_gateway_zones
  tags                    = var.common_tags
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count            = var.create_nat_gateway ? 1 : 0
  nat_gateway_id   = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}

# Associate NAT Gateway with Application Subnet
resource "azurerm_subnet_nat_gateway_association" "application" {
  count          = var.create_nat_gateway && var.associate_nat_with_application ? 1 : 0
  subnet_id      = azurerm_subnet.application.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Associate NAT Gateway with Presentation Subnet
resource "azurerm_subnet_nat_gateway_association" "presentation" {
  count          = var.create_nat_gateway && var.associate_nat_with_presentation != false ? 1 : 0
  subnet_id      = azurerm_subnet.presentation.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

