data "template_file" "script" {
  template = file("${path.module}/scripts/ds-params.sh")
  vars = {
    DSDISTURL         = var.link_To_DS_Build
		STACKNAME         = "${var.prefix}-launch-configuration"
		DeploymentName    = var.prefix
		REGION            = azurerm_resource_group.rg.location
    DSRESOURCE_GROUP  = azurerm_resource_group.rg.name
    BackupStorageName = var.BackupStorageName
    ResourceGroupStorage = var.ResourceGroupStorage
		DSLICTYPE         = var.ds_license_type
    DSAdminPassword   = var.DS_Admin_Password
		TRG_DBTYPE        = var.Target_DB_Type
    TRG_DBPASSWD      = var.Target_DB_Password
		TRG_DBHOST        = var.Target_DB_Host
		TRG_DBPORT        = var.Target_DB_Port
		TRG_DBNAME        = var.Target_DB_Name
		TRG_DBUSER        = var.Target_DB_Login
    HA_DBPASSWD       = var.DS_Database_Admin_Password
		HA_DBTYPE         = var.DS_Database_Type
		HA_DBHOST         = azurerm_postgresql_flexible_server.PostgreSQLServerDict.fqdn
		HA_DBPORT         = var.DS_Database_Port
		HA_DBNAME         = azurerm_postgresql_flexible_server_database.dsdictionary.name
		HA_DBUSER         = azurerm_postgresql_flexible_server.PostgreSQLServerDict.administrator_login
		HA_AUTYPE         = "1"
    HA_AUPASSWD       = var.DS_Database_Admin_Password
		HA_AUHOST         = azurerm_postgresql_flexible_server.PostgreSQLServerAudit.fqdn
		HA_AUPORT         = var.DS_Database_Port
		HA_AUNAME         = azurerm_postgresql_flexible_server_database.dsaudit.name
		HA_AUUSER         = azurerm_postgresql_flexible_server.PostgreSQLServerAudit.administrator_login
    
  }
}

data "template_cloudinit_config" "example" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
write_files:
  - content: |
      ${base64encode(file("${path.module}/scripts/ds-params.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds-params.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/ds-manip.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds-manip.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/pre-setup.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/pre-setup.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/ds-setup.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds-setup.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/backup-prepare.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/backup-prepare.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/backup-upload.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/backup-upload.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/azure-ds-setup.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/azure-ds-setup.sh
    permissions: '0750'
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.script.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/scripts/user-data.sh")
  }

}
