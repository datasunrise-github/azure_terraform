#Create Virtual Network 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-dsnetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name = "${var.prefix}-DataSunrise-VNET-Created-By-Terraform"
  } 

  depends_on = [ azurerm_resource_group.rg ]
}

#Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-dssubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"]

  depends_on = [ azurerm_virtual_network.vnet ]

}

#Create Public Ip
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-dspip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    Name = "${var.prefix}-DataSunrise-PIP-Created-By-Terraform"
  }
}

#Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-dsnic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

}

#Create Security Group and Rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-dsnsg"
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
    destination_port_range     = "11000-11010"
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
    destination_port_range     = "${var.Target_DB_Port}"
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
    Name = "${var.prefix}-DataSunrise-NSG-Created-By-Terraform"
  } 
  
}

#Create LoadBalancer with rules
resource "azurerm_lb" "loadbalancer" {
  name                = "${var.prefix}-dslb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  tags = {
    Name = "${var.prefix}-DataSunrise-LoadBalancer-Created-By-Terraform"
  } 
}

resource "azurerm_lb_backend_address_pool" "backend_lb" {
  name                = "DSBackEndAddressPool"
  loadbalancer_id     = azurerm_lb.loadbalancer.id
}

resource "azurerm_lb_rule" "nlb_webui" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "dswebui"
  protocol                       = "Tcp"
  frontend_port                  = 11000
  backend_port                   = 11000
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.dswebui.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_lb.id]
}

resource "azurerm_lb_rule" "lb_proxy_port" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "proxyport"
  protocol                       = "Tcp"
  frontend_port                  = var.Target_DB_Port
  backend_port                   = var.Target_DB_Port
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.probe_proxy_port.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_lb.id]
}

resource "azurerm_lb_rule" "nlb_ssh" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.ssh.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_lb.id]
}

resource "azurerm_lb_probe" "dswebui" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "${var.prefix}DS-Probe"
  port            = 11000
}

resource "azurerm_lb_probe" "ssh" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "${var.prefix}SSH-Probe"
  port            = 22
}

resource "azurerm_lb_probe" "probe_proxy_port" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "${var.prefix}proxyPortProbe"
  port            = var.Target_DB_Port
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
