data "template_file" "script" {
  template = file("${path.module}/scripts/ds_install.sh")
  vars = {
    DSDISTURL = var.link_To_DS_Build
		STACKNAME = "${var.prefix}-launch-configuration"
		DeploymentName = var.prefix
		REGION = azurerm_resource_group.rg.location
		DSLICTYPE = var.ds_license_type
    DSAdminPassword = var.DS_Admin_Password
		TRG_DBTYPE = var.Target_DB_Type
    TRG_DBPASSWD = var.Target_DB_Password
		TRG_DBHOST = var.Target_DB_Host
		TRG_DBPORT = var.Target_DB_Port
		TRG_DBNAME = var.Target_DB_Name
		TRG_DBUSER = var.Target_DB_Login
		TRG_DBPROXYPORT = var.Target_DBProxy_Port
    HA_DBPASSWD = var.DS_Database_Admin_Password
		HA_DBTYPE = var.DS_Database_Type
		HA_DBHOST = azurerm_postgresql_flexible_server.FlexPostgreSQLServerDict.fqdn
		HA_DBPORT = var.DS_Database_Port
		HA_DBNAME = azurerm_postgresql_flexible_server_database.DSDicttionary.name
		HA_DBUSER = azurerm_postgresql_flexible_server.FlexPostgreSQLServerDict.administrator_login
		HA_AUTYPE = "1"
    HA_AUPASSWD = var.DS_Database_Admin_Password
		HA_AUHOST = azurerm_postgresql_flexible_server.FlexPostgreSQLServerAudit.fqdn
		HA_AUPORT = var.DS_Database_Port
		HA_AUNAME = azurerm_postgresql_flexible_server_database.DSAUdit.name
		HA_AUUSER = azurerm_postgresql_flexible_server.FlexPostgreSQLServerAudit.administrator_login
    
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
      ${base64encode(file("${path.module}/scripts/ds_install.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds_install.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/ds-manip.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds-manip.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/install_libraries.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/install_libraries.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/ds_pre_setup.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds_pre_setup.sh
    permissions: '0750'
  - content: |
      ${base64encode(file("${path.module}/scripts/ds_setup.sh"))}
    encoding: b64
    owner: root:root
    path: /opt/cooked/ds_setup.sh
    permissions: '0750'
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content = data.template_file.script.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content = file("${path.module}/scripts/user_data.sh")
  }

}
