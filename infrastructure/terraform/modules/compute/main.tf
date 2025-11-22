# Presentation Tier VM Scale Set (Web/Frontend)
resource "azurerm_linux_virtual_machine_scale_set" "presentation" {
  count                  = var.create_presentation_vmss ? 1 : 0
  name                   = var.presentation_vmss_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku                    = var.presentation_vm_sku
  instances              = var.presentation_instance_count
  admin_username         = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = var.presentation_os_disk_type
    disk_size_gb        = var.presentation_os_disk_size_gb
    caching             = "ReadWrite"
  }

  network_interface {
    name    = "nic-presentation"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.presentation_subnet_id
      # Automatically add VMSS instances to Application Gateway backend pool
      application_gateway_backend_address_pool_ids = var.application_gateway_backend_address_pool_id != null ? [var.application_gateway_backend_address_pool_id] : []
    }
  }

  tags = var.common_tags
}

# Application Tier VM Scale Set (API/Backend)
resource "azurerm_linux_virtual_machine_scale_set" "application" {
  count                  = var.create_application_vmss ? 1 : 0
  name                   = var.application_vmss_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku                    = var.application_vm_sku
  instances              = var.application_instance_count
  admin_username         = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = var.application_os_disk_type
    disk_size_gb        = var.application_os_disk_size_gb
    caching             = "ReadWrite"
  }

  network_interface {
    name    = "nic-application"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.application_subnet_id
      load_balancer_backend_address_pool_ids = var.internal_lb_backend_address_pool_id != null ? [var.internal_lb_backend_address_pool_id] : []
    }
  }

  tags = var.common_tags
}

# Autoscaling for Presentation Tier
resource "azurerm_monitor_autoscale_setting" "presentation" {
  count               = var.create_presentation_vmss && var.enable_autoscaling ? 1 : 0
  name                = "autoscale-presentation"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.presentation[0].id

  profile {
    name = "default"

    capacity {
      default = var.presentation_instance_count
      minimum = var.presentation_min_instances
      maximum = var.presentation_max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.presentation[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.presentation_scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.presentation[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.presentation_scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.common_tags
}

# Autoscaling for Application Tier
resource "azurerm_monitor_autoscale_setting" "application" {
  count               = var.create_application_vmss && var.enable_autoscaling ? 1 : 0
  name                = "autoscale-application"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.application[0].id

  profile {
    name = "default"

    capacity {
      default = var.application_instance_count
      minimum = var.application_min_instances
      maximum = var.application_max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.application[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.application_scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.application[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.application_scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.common_tags
}

