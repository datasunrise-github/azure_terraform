# Create User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "dsidentity" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${var.prefix}-identity"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.prefix}-DataSunrise-Identity-Created-By-Terraform"
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
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/*/read",
      "Microsoft.Storage/*/write",
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
    not_actions  = []
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

# Get existing Key Vault
data "azurerm_key_vault" "kv" {
  name                = var.azure_keyvault_name
  resource_group_name = var.azure_keyvault_rg_name
}
# Get existing Key
data "azurerm_key_vault_secret" "ssh_key" {
  name         = var.ssh_key_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
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
  enabled_for_template_deployment = true
  enabled_for_deployment          = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", 
      "List", 
      "Set", 
      "Delete",
      "Purge"
    ]
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "${var.prefix}-DataSunrise-KeyVault-Created-By-Terraform"
  } 
}

resource "azurerm_key_vault_access_policy" "ds_identity_app" {
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
  tenant_id    = azurerm_user_assigned_identity.dsidentity.tenant_id
  object_id    = azurerm_user_assigned_identity.dsidentity.principal_id 
  
  secret_permissions = [
    "Get", 
    "List", 
    "Set", 
    "Delete", 
    "Recover", 
    "Backup", 
    "Restore", 
    "Purge"
  ]
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_key_vault_secret" "ds_license_key" {
  name         = "ds-secret-licensekey"
  value        = var.DS_License_Key
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

resource "azurerm_key_vault_secret" "targetdb_secret_password" {
  name         = "tdb-secret-password"
  value        = var.Target_DB_Password
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

resource "azurerm_key_vault_secret" "ds_secret_admin_password" {
  name         = "ds-secret-admin-password"
  value        = var.DS_Admin_Password
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}

resource "azurerm_key_vault_secret" "ds_secret_config_password" {
  name         = "ds-secret-config-password"
  value        = var.DS_Database_Admin_Password
  key_vault_id = azurerm_key_vault.DS_Key_Vault.id
}