variable "prefix" {
  type = string
  description = "Name prefix that will be used for Virtual Machine Scale Set resources"
  validation {
    condition = length(var.prefix) >= 5 && length(var.prefix) <= 15
    error_message = "Name prefix must be at least 5 characters and at most 15 characters."
  }

  validation {
    condition = can(regex("^[a-z0-9]+$", var.prefix))
    error_message = "Name prefix must only contain lowercase characters and numbers."
  }
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created."
}

variable "admin_Username" {
  type = string
  description = "Linux VM User Account Name. For example, linuxuser"
  
}

variable "azure_keyvault_name" {
  type = string
  description = "The name of the existing Key Vault where the SSH public key secret is stored"
}

variable "azure_keyvault_rg_name" {
  type = string
  description = "Name of the Resource Group where created Key Vault with SSH Public Key"
}

variable "ssh_key_secret_name" {
  type = string
  description = "Secret name containing public part of RSA key"
}

variable "roleName" {
  type = string
  default = "DataSunrise"
  description = "Name of the role that will be assigned in Managed Identity."
  
}

variable "BackupStorageName" {
  type = string
  default = ""
}

variable "ResourceGroupStorage" {
  type = string
  default = ""
}

variable "vmsize" {
  type = string
  default = "Standard_D2_v2"
  description = "Size of the Virtual Machine. Depends on the Location and Availability Set"
}

variable "vmcount" {
  type = number
  default = 1
  description = "Count of instances of the VM being created"
}

variable "ds_license_type" {
  type = string
  default = "BYOL"
  description = "BYOL"
}

variable "virtual_Network_Name" {
  type = string
  default = "vnet"
  description = "Enter the name of the Virtual Network. default = vnet"
}

variable "subnet_Name" {
  type = string
  default = "subnet"
  description = "Type existing Subnet name"  
}

variable "link_To_DS_Build" {
  type = string
  description = "Link to DataSunrise Suite build"
}

variable "DS_Admin_Password" {
  type = string
  description = "DS admin password"
  
}

variable "DS_License_Key" {
  description = "!!!Important!!! for correct key substitution, if there are double quotes in the key, then it is necessary to make a concatenation using a backslash (\")"
}

variable "DS_Database_Type" {
  type = string
  default = "postgresql"
  description = "Type of database to be used as Dictionary and Audit database for DS configuration"
}

variable "DS_Database_PG_Version" {
  type = string
  description = "(Optional) The version of PostgreSQL Flexible Server to use. Possible values are 11,12, 13, 14 and 15. Required when create_mode is Default."
  default = "16"
  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.DS_Database_PG_Version)
    error_message = "The value of the version property of the PostgreSQL is invalid."
  }
}

variable "DS_Database_Port" {
  type = string
  default = "5432"
  description = "Dictionary and Audit Database port" 
}

variable "DS_Database_Admin_Login" {
  type = string
  default = "dsuser"
  description = "Administrator login for Dictionary and Audit database servers"
  validation {
    condition = length(var.DS_Database_Admin_Login) >= 1 && length(var.DS_Database_Admin_Login) <= 63
    error_message = "Admin username must be at least 1 character and at most 63 characters."
  }

  validation {
    condition = can(regex("^[a-zA-Z0-9]+$", var.DS_Database_Admin_Login))
    error_message = "Admin username must only contain characters and numbers."
  }

  validation {
    condition = !can(index(["azure_superuser", "azure_pg_admin", "admin", "administrator", "root", "guest", "public"], var.DS_Database_Admin_Login)) && !can(regex("^pg_", var.DS_Database_Admin_Login))
    error_message = "Admin login name cannot be 'azure_superuser', 'azure_pg_admin', 'admin', 'administrator', 'root', 'guest', 'public' or start with 'pg_'."
  }
}

variable "DS_Database_Admin_Password" {
  type = string
  description = "Administrator password for Dictionary and Audit database servers"
}

variable "DS_Database_Backup_Retention_Days" {
  type = number
  description = "Dictionary and Audit database servers backup retention days"
}

variable "Audit_Database_Name" {
  type = string
  default = "dsaudit"
  description = "Audit database name. For example, dsaudit"
  
}

variable "Dictionary_Database_Name" {
  type = string
  default = "dsdictionary"
  description = "Dictionary database name. For example, dsdictionary"
}

variable "dictionary_db_storage_size" {
  description = "(Optional) The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408."
  type = string
  default = "65536"
}

variable "audit_db_storage_size" {
  description = "(Optional) The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408."
  type = string
  default = "262144"
}

variable "audit_db_class" {
  type = string
  description = "Instance class for audit database"
}

variable "dictionary_db_class" {
  type = string
  description = "Instance class for dictionary database"
}

variable "postgresql_configurations" {
  description = "PostgreSQL configurations to enable."
  type        = map(string)
  default = {
    "pgbouncer.enabled" = "true",
    "azure.extensions"  = "PG_TRGM"
  }
}

variable "Target_DB_Name" {
  type = string
  description = "Target database name. For example, postgres"
}

variable "Target_DB_Type" {
  type = string
  description = "Target database type. For example, postgresql"
}

variable "Target_DB_Host" {
  type = string
  description = "Target database host. For example, postgresqserver.postgres.database.azure.com"
}

variable "Target_DB_Port" {
  type = string
  description = "Target database port. For example, 5432"
}

variable "Target_DB_Login" {
  type = string
  description = "Target database login. For example, postgres"
}

variable "Target_DB_Password" {
  type = string
  description = "Target database login password" 
}