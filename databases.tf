#Create Virtual Network Rule For Database
resource "azurerm_postgresql_flexible_server_firewall_rule" "db_fw_rule_dict" {
  name             = "dictionary-fw"
  server_id        = azurerm_postgresql_flexible_server.FlexPostgreSQLServerDict.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "db_fw_rule_audit" {
  name             = "audit-fw"
  server_id        = azurerm_postgresql_flexible_server.FlexPostgreSQLServerAudit.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#Create a PostgreSQL Flexible Server Dictionary.
resource "azurerm_postgresql_flexible_server" "FlexPostgreSQLServerDict" {
  name                          = "${var.prefix}-psqlflexibleserverdictionary"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = var.DS_Database_PG_Version
  administrator_login           = var.DS_Database_Admin_Login
  administrator_password        = var.DS_Database_Admin_Password
  storage_mb                    = var.dictionary_db_storage_size
  sku_name                      = var.dictionary_db_class
  zone ="1"
  # high_availability {
  #   mode = ""
  # }
  tags = {
    Name = "${var.prefix}-DataSunrise-Dictionary-Server"
  } 

}

#Create Dictionary DataBase
resource "azurerm_postgresql_flexible_server_database" "DSDicttionary" {
  name      = var.Dictionary_Database_Name
  server_id = azurerm_postgresql_flexible_server.FlexPostgreSQLServerDict.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

#Create a PostgreSQL Flexible Server Audit.
resource "azurerm_postgresql_flexible_server" "FlexPostgreSQLServerAudit" {
  name                          = "${var.prefix}-psqlflexibleserveraudit"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = var.DS_Database_PG_Version
  administrator_login           = var.DS_Database_Admin_Login
  administrator_password        = var.DS_Database_Admin_Password
  storage_mb                    = var.audit_db_storage_size
  sku_name                      = var.audit_db_class
  zone ="1"
  # high_availability {
  #   mode = "ZoneRedundant"

  # }

  tags = {
    Name = "${var.prefix}-DataSunrise-Audit-Server"
  }

}

#Create Audit DataBase
resource "azurerm_postgresql_flexible_server_database" "DSAUdit" {
  name      = var.Audit_Database_Name
  server_id = azurerm_postgresql_flexible_server.FlexPostgreSQLServerAudit.id
  collation = "en_US.utf8"
  charset   = "utf8"
}