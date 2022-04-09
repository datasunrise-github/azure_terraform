variable "prefix" {
  type = string
  description = "Name prefix that will be used for Virtual Machine Scale Set resources"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created."
}

variable "admin_Username" {
  type = string
  description = "Linux VM User Account Name. For example, linuxuser"
  
}

variable "admin_Password" {
  type = string
  description = "Linux VM User Password" 
}

variable "roleName" {
  type = string
  default = "DataSunrise"
  description = "Name of the role that will be assigned in Managed Identity."
  
}

variable "vmSize" {
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
  description = "PostgreSQL Version"
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
  description = "The size of the database (Mb), minimum restriction by Azure is 32768Mb"
  default = 32768
}

variable "audit_db_storage_size" {
  description = "The size of the database (Mb), minimum restriction by Azure is 32768Mb"
  default = 32768
}

variable "audit_db_class" {
  type = string
  description = "Instance class for audit database"
}

variable "dictionary_db_class" {
  type = string
  description = "Instance class for dictionary database"
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

variable "Target_DBProxy_Port" {
  type = number
  description = "Target database proxy port. For example, 5433. Must be greater than the TargetDBPort"

}

variable "Target_DB_Login" {
  type = string
  description = "Target database login. For example, postgres"
}

variable "Target_DB_Password" {
  type = string
  description = "Target database login password" 
}