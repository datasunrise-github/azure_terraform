#Create Virtual Network Rule For Database
resource "azurerm_postgresql_flexible_server_firewall_rule" "db_fw_rule_dict" {
  name             = "ds-dictionary-fw"
  server_id        = azurerm_postgresql_flexible_server.PostgreSQLServerDict.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "db_fw_rule_audit" {
  name             = "ds-audit-fw"
  server_id        = azurerm_postgresql_flexible_server.PostgreSQLServerAudit.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#Create a PostgreSQL Flexible Server Dictionary.
resource "azurerm_postgresql_flexible_server" "PostgreSQLServerDict" {
  name                          = "${var.prefix}-dictionary"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = var.DS_Database_PG_Version
  administrator_login           = var.DS_Database_Admin_Login
  administrator_password        = var.DS_Database_Admin_Password
  storage_mb                    = var.dictionary_db_storage_size
  sku_name                      = var.dictionary_db_class

  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_subnet.subnet,
  ]

  tags = {
    Name = "${var.prefix}-DataSunrise-Dictionary-Server-Created-By-Terraform"
  } 

}

#Create Postgres Dictionary Database
resource "azurerm_postgresql_flexible_server_database" "dsdictionary" {
  name      = var.Dictionary_Database_Name
  server_id = azurerm_postgresql_flexible_server.PostgreSQLServerDict.id
  collation = "en_US.utf8"
  charset   = "utf8"

  depends_on = [ azurerm_postgresql_flexible_server.PostgreSQLServerDict ]
}

#Create a PostgreSQL Flexible Server Audit.
resource "azurerm_postgresql_flexible_server" "PostgreSQLServerAudit" {
  name                          = "${var.prefix}-audit"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = var.DS_Database_PG_Version
  administrator_login           = var.DS_Database_Admin_Login
  administrator_password        = var.DS_Database_Admin_Password
  storage_mb                    = var.audit_db_storage_size
  sku_name                      = var.audit_db_class

  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_subnet.subnet,
  ]

  tags = {
    Name = "${var.prefix}-DataSunrise-Audit-Server-Created-By-Terraform"
  }

}

#Create Postgres Audit Database
resource "azurerm_postgresql_flexible_server_database" "dsaudit" {
  name      = var.Audit_Database_Name
  server_id = azurerm_postgresql_flexible_server.PostgreSQLServerAudit.id
  collation = "en_US.utf8"
  charset   = "utf8"

  depends_on = [ azurerm_postgresql_flexible_server.PostgreSQLServerAudit ]
}