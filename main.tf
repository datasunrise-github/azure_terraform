#Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-ds-resource-group"
  location = var.location

  tags = {"CreatedBy" = "Terraform"}
}

# Generate random text for a unique vm compute name prefix
resource "random_id" "randomId" {
  keepers = {
  }

  byte_length = 8
}

resource "azurerm_linux_virtual_machine_scale_set" "dsvm" {
  name                            = "${var.prefix}-ds-scaleset"
  computer_name_prefix            = "ds-${random_id.randomId.hex}-"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = var.vmsize
  instances                       = var.vmcount
  admin_username                  = var.admin_Username
  custom_data                     = data.template_cloudinit_config.example.rendered
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_Username
    public_key = data.azurerm_key_vault_secret.ssh_key.value
  }

  source_image_reference {
    publisher = "datasunrise"
    sku       = "datasunrise"
    offer     = "datasunrise-database-security-suite"
    version   = "latest"
  }

  plan {
    name      = "datasunrise"
    product   = "datasunrise-database-security-suite"
    publisher = "datasunrise"
  }

  network_interface {
    name    = "nicvm"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_lb.id]
    }
    network_security_group_id = azurerm_network_security_group.nsg.id
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.dsidentity.id,
    ]
  }

  depends_on = [
    azurerm_network_security_group.nsg, 
    azurerm_lb_probe.ssh, 
    azurerm_key_vault.DS_Key_Vault,
    azurerm_role_definition.role_defenition, 
    azurerm_key_vault_secret.ds_secret_admin_password]

  tags = {
    Name = "${var.prefix}-DataSunrise-VMSS-Created-By-Terraform"
  } 
}

resource "azurerm_monitor_autoscale_setting" "autoscalesettings" {
  name                = "autoscale-config"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.dsvm.id

  profile {
    name = "AutoScale"

    capacity {
      default = var.vmcount
      minimum = var.vmcount
      maximum = var.vmcount
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.dsvm.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.dsvm.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 20
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

    tags = {
    Name = "${var.prefix}-DataSunrise-AutoscaleSettings-Created-By-Terraform"
  } 
}