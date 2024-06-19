# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Microsoft Azure Cloud 
# Version 0.1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

output "DataSunriseConsoleURL" {
  value = "https://${azurerm_public_ip.public_ip.ip_address}:11000"
}