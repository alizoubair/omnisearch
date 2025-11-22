# Application Gateway Public IP
# Note: Standard Application Gateway requires Standard public IP SKU
resource "azurerm_public_ip" "app_gateway" {
  count               = var.create_application_gateway ? 1 : 0
  name                = var.application_gateway_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  count               = var.create_application_gateway ? 1 : 0
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.application_gateway_sku_name
    tier     = var.application_gateway_sku_tier
    capacity = var.enable_app_gateway_autoscaling ? null : var.application_gateway_capacity
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"  # Updated TLS policy (replaces deprecated AppGwSslPolicy20150501)
  }

  dynamic "autoscale_configuration" {
    for_each = var.enable_app_gateway_autoscaling ? [1] : []
    content {
      min_capacity = var.application_gateway_min_capacity
      max_capacity = var.application_gateway_max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.app_gateway_subnet_id != null ? var.app_gateway_subnet_id : var.presentation_subnet_id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "app-gateway-frontend-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway[0].id
  }

  backend_address_pool {
    name = "backend-pool"
    # VMSS instances are automatically added via application_gateway_backend_address_pool_ids
    # in the VMSS network interface configuration
  }

  # Health probe for backend servers
  probe {
    name                                      = "backend-health-probe"
    protocol                                  = "Http"
    path                                      = var.application_gateway_probe_path
    pick_host_name_from_backend_http_settings = true
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    match {
      status_code = ["200"]
    }
  }

  backend_http_settings {
    name                                = "backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = var.application_gateway_backend_port
    protocol                            = "Http"
    request_timeout                     = 20
    probe_name                          = "backend-health-probe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "app-gateway-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
  }

  tags = var.common_tags
}


# Internal Load Balancer
resource "azurerm_lb" "internal" {
  count               = var.create_internal_lb ? 1 : 0
  name                = var.internal_lb_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "internal-frontend"
    subnet_id                     = var.application_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.internal_lb_private_ip
  }

  tags = var.common_tags
}

# Internal Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "internal" {
  count           = var.create_internal_lb ? 1 : 0
  name            = "internal-backend-pool"
  loadbalancer_id = azurerm_lb.internal[0].id
}

# Internal Load Balancer Health Probe
resource "azurerm_lb_probe" "internal" {
  count           = var.create_internal_lb ? 1 : 0
  name            = "internal-health-probe"
  loadbalancer_id = azurerm_lb.internal[0].id
  port            = var.internal_lb_probe_port
  protocol        = "Http"
  request_path    = var.internal_lb_probe_path
  interval_in_seconds = 15
  number_of_probes   = 2
}

# Internal Load Balancer Rule
resource "azurerm_lb_rule" "internal" {
  count                          = var.create_internal_lb ? 1 : 0
  name                           = "internal-lb-rule"
  loadbalancer_id                = azurerm_lb.internal[0].id
  protocol                       = "Tcp"
  frontend_port                  = var.internal_lb_frontend_port
  backend_port                   = var.internal_lb_backend_port
  frontend_ip_configuration_name = "internal-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.internal[0].id]
  probe_id                       = azurerm_lb_probe.internal[0].id
}

# NAT Pool for SSH Access (optional)
resource "azurerm_lb_nat_pool" "ssh" {
  count                          = var.create_internal_lb && var.enable_nat_pool ? 1 : 0
  name                           = "ssh-nat-pool"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.internal[0].id
  protocol                       = "Tcp"
  frontend_port_start            = var.nat_pool_frontend_port_start
  frontend_port_end              = var.nat_pool_frontend_port_end
  backend_port                   = var.nat_pool_backend_port
  frontend_ip_configuration_name = "internal-frontend"
}

