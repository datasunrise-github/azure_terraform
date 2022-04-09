terraform {
  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

# Create User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "dsidentity" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${var.prefix}-identity"

 lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.prefix}-Identity"
  }  
}

#Create role Assignments (IAmRole)
data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {

}


resource "azurerm_role_definition" "role_defenition" {
  name               = "${var.prefix}-custom-role-definition"
  scope              = data.azurerm_subscription.primary.id

  permissions {
    actions     = [
      "Microsoft.Storage/*/read",
      "Microsoft.Network/*/read",
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Authorization/*/read",
      "Microsoft.ResourceHealth/availabilityStatuses/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Insights/alertRules/*",
      "Microsoft.Support/*",
      "Microsoft.KeyVault/*/read",
    ]
    not_actions = []
    data_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]
}

resource "azurerm_role_assignment" "dsroleAssignment" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.role_defenition.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.dsidentity.principal_id

}

#Create key vault secret 
resource "azurerm_key_vault" "DS_Key_Vault" {
  name                       = "${var.prefix}-keyvault"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  soft_delete_enabled        = true
  enabled_for_template_deployment = true
  enabled_for_deployment          = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "set",
      "get",
      "list",
      "purge",
      "delete",
      "recover",
    ]
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "${var.prefix}-DataSunrise-KeyVault"
  } 
}

resource "azurerm_key_vault_access_policy" "ds_identity_app" {
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
  tenant_id = azurerm_user_assigned_identity.dsidentity.tenant_id
  object_id = azurerm_user_assigned_identity.dsidentity.principal_id 
  
  secret_permissions = [
    "set",
    "get",
    "list",
    "purge",
    "delete",
    "recover",
  ]
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_key_vault_secret" "ds_license_key" {
  name = "ds-secret-licensekey"
  value = var.DS_License_Key
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

resource "azurerm_key_vault_secret" "targetdb_secret_password" {
  name = "targetdb-secret-password"
  value = var.Target_DB_Password
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

resource "azurerm_key_vault_secret" "ds_secret_admin_password" {
  name = "ds-secret-admin-password"
  value = var.DS_Admin_Password
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

#Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    Name = "${var.prefix}-rg"
  } 
}


#Create storage account
resource "azurerm_storage_account" "storage" {
  name                     = "dsdiagsa${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name = "${var.prefix}-Storage"
  } 

}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    #Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

#Create Virtual Network 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name = "${var.prefix}-VNET"
  } 
}

#Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"] 
}

#Create Public Ip
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"

}

#Create Network Interface
resource "azurerm_network_interface" "nic2" {
  name                      = "${var.prefix}-nic2"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

}

#Create Security Group and Rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
  
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ds"
    priority                   = 200
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "11000"
    destination_address_prefix = "*"
  }

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "TargetDBPort"
    priority                   = 300
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "${var.Target_DB_Port}-${var.Target_DBProxy_Port}"
    destination_address_prefix = "*"
  }

  security_rule {
    access                     = "Allow"
    direction                  = "Outbound"
    name                       = "Outbound"
    priority                   = 400
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.prefix}-NSG"
  } 
  
}

#Create LoadBalancer with rules
resource "azurerm_lb" "loadbalancer" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "publicIp"
    public_ip_address_id = azurerm_public_ip.public_ip.id
    
  }

  tags = {
    Name = "${var.prefix}-LoadBalancer"
  } 
}

resource "azurerm_lb_backend_address_pool" "backend_lb" {
  name                = "backend-pool"
  #resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
}

resource "azurerm_lb_rule" "nlb_webui" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "dswebui"
  protocol                       = "Tcp"
  frontend_port                  = 11000
  backend_port                   = 11000
  frontend_ip_configuration_name = "publicIp"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_lb.id
}

resource "azurerm_lb_nat_pool" "lb_nat_pool_tragetdb" {
  name                           = "nat-pool-targetdb"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  frontend_ip_configuration_name = "publicIp"
  protocol                       = "Tcp"
  frontend_port_start            = var.Target_DB_Port
  frontend_port_end              = var.Target_DBProxy_Port
  backend_port                   = var.Target_DB_Port
}

resource "azurerm_lb_rule" "lb_proxy_port" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "proxyport"
  protocol                       = "Tcp"
  frontend_port                  = var.Target_DBProxy_Port
  backend_port                   = var.Target_DBProxy_Port
  frontend_ip_configuration_name = "publicIp"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_lb.id
}

resource "azurerm_lb_rule" "nlb_ssh" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "publicIp"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_lb.id
}

resource "azurerm_lb_probe" "dswebui" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "${var.prefix}SFHttpsGatewayProbe"
  port                = 11000
}

resource "azurerm_lb_probe" "ssh" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "${var.prefix}SSHGatewayProbe"
  port                = 22
}

resource "azurerm_lb_probe" "probe_proxy_port" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "${var.prefix}proxyPortGatewayProbe"
  port                = var.Target_DBProxy_Port
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# resource "azurerm_network_interface_backend_address_pool_association" "lb_association" {
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_lb.id
#   ip_configuration_name   = "primary"
#   network_interface_id    = azurerm_network_interface.nic2.id
# }

resource "azurerm_linux_virtual_machine_scale_set" "dsvm" {
  name                            = "DSScaleSet"
  computer_name_prefix            = "ds-"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = var.vmSize
  instances                       = var.vmcount
  admin_username                  = var.admin_Username
  admin_password                  = var.admin_Password
  custom_data                     = data.template_cloudinit_config.example.rendered
  disable_password_authentication = false


  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_8"
    version   = "latest"
  }

  network_interface {
    name    = "nicvm"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_lb.id]
      load_balancer_inbound_nat_rules_ids    = [
        azurerm_lb_nat_pool.lb_nat_pool_tragetdb.id
      ]
    }
    network_security_group_id = azurerm_network_security_group.nsg.id
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.dsidentity.id,
    ]
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
  }

  # Since these can change via auto-scaling outside of Terraform,
  # let's ignore any changes to the number of instances
  lifecycle {
    ignore_changes = [instances]
  }

  depends_on = [azurerm_network_security_group.nsg]

  tags = {
    Name = "${var.prefix}-VMSS"
  } 
}

resource "azurerm_monitor_autoscale_setting" "ass" {
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
    Name = "${var.prefix}-ASS"
  } 
}