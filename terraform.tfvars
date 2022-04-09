# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Microsoft Azure Cloud 
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Please replace xxxxxxxxx with values that correspond to your environment
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ------------------------------------------------------------------------------
# Virtual Machine Configuration
# ------------------------------------------------------------------------------
prefix                            = "xxxxxxxxx" 
#description = "Name that will be used as the prefix to the resources' names that will be created by the Terraform script (only in lower case, not more than 15 symbols and not less than 5 symbols)"

location                          = "xxxxxxxxx" 
#description = "The Azure Region in which all resources should be created."

admin_Username                    = "xxxxxxxxx" 
#default = "dsuser"
#description = "VM User Account Name. For example, dsuser"

admin_Password                    = "xxxxxxxxx" 
#description = "VM User Password" 

vmcount                           = "xxxxxxxxx" 
#default = "1"
#description = "Count of instances of the VM being created."

vmSize                            = "xxxxxxxxx" 
#description = "Virtual Machine type for DataSunrise instance. Depends on the Location and Availability Set"

# ------------------------------------------------------------------------------
# DataSunrise Configuration
# ------------------------------------------------------------------------------

link_To_DS_Build                  = "xxxxxxxxx"
#description = "Url of the DataSunrise distribution `.run` package. #Make sure that this URL will be accessible from your PC"

DS_Admin_Password                 = "xxxxxxxxx"
#description = "DataSunrise admin's password. The password must contain at least 8 characters, lower and upper case, numbers and special characters."

DS_License_Key                    = "xxxxxxxxx"
#description = "!!!Important!!! for correct key substitution, if there are double quotes in the key, then it is necessary to make a concatenation using a backslash (\")"

# ------------------------------------------------------------------------------
# Dictionary & Audit Database Configuration
# ------------------------------------------------------------------------------

dictionary_db_class               = "xxxxxxxxx"
#description = "Instance class for dictionary database (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)"

dictionary_db_storage_size        = "xxxxxxxxx"
#description = "The size of the database (Mb), minimum restriction by Azure is 32768Mb"
#default = 32768

Dictionary_Database_Name          = "xxxxxxxxx"
#default     = "dsdictionary"
#description = "Dictionary DB name. default = dsdictionary"


audit_db_class                    = "xxxxxxxxx"
#description = "Instance class for audit database"

audit_db_storage_size             = "xxxxxxxxx"
#description = "The size of the database (Mb), minimum restriction by Azure is 32768Mb"
#The max storage allowed for the PostgreSQL Flexible Server. 
#Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432
#default = 32768

Audit_Database_Name               = "xxxxxxxxx"
#default     = "dsaudit"
#description = "Audit DB name. Default = dsaudit"

DS_Database_PG_Version            = "xxxxxxxxx"
#AllowedValues: "11", "12", "13"

DS_Database_Port                  = "xxxxxxxxx"
#default = "5432"
#description = "Dictionary and Audit Database port"

DS_Database_Admin_Login           = "xxxxxxxxx"
#default     = "dsuser"
#description = "Administrator login for Dictionary and Audit database servers."
#Admin username must be at least 1 characters and at most 63 characters.
#Admin username must only contain characters and numbers.
#Admin login name cannot be 'azure_superuser', 'azure_pg_admin', 'admin', 'administrator', 'root', 'guest', 'public' or start with 'pg_'.

DS_Database_Admin_Password        = "xxxxxxxxx"
#description = "Administrator password for Dictionary and Audit database servers. 
#Your password must be at least 8 characters and at most 128 characters.
#Your password must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.).
#Your password cannot contain all or part of the login name. Part of a login name is defined as three or more consecutive alphanumeric characters."

DS_Database_Backup_Retention_Days = "xxxxxxxxx"
#description = "Dictionary and Audit database servers backup retention days. The default backup retention period is seven days and can be stored up to 35 days."



# ------------------------------------------------------------------------------
# Target Database Configuration
# ------------------------------------------------------------------------------

Target_DB_Name          = "xxxxxxxxx"
#description = "Target Database internal database name e.g. master for MSSQL or postgres for PostgreSQL"

Target_DB_Type          = "xxxxxxxxx"
#description = "Target Database Instance Type"
#Allowed values: "aurora mysql", "aurora postgresql", "greenplum", "hive", "mariadb", "mysql", "mssql", "netezza", "oracle", "postgresql", "redshift", "teradata", "any"

Target_DB_Host          = "xxxxxxxxx"
#description = "Target Database Instance Host"

Target_DB_Port          = "xxxxxxxxx"
#description = "Target Database Instance Port"

Target_DBProxy_Port     = "xxxxxxxxx"
#description = "Target database proxy port. For example, 5433. Must be greater than the Target_DB_Port"

Target_DB_Login         = "xxxxxxxxx"
#description = "Target database login. For example, postgres"

Target_DB_Password      = "xxxxxxxxx"
#discription = "Target Database Password"
