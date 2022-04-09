#!/bin/bash

rpm --import https://packages.microsoft.com/keys/microsoft.asc

sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

yum install azure-cli -y
echo "Azure CLI was successfully installed" >> $PREP_LOG

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum install jq -y
echo "jq was successfully installed" >> $PREP_LOG

yum install java-1.8.0-openjdk -y

yum install unixODBC -y
echo "unixODBC install OK" >> $PREP_LOG

curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo

ACCEPT_EULA=Y yum install msodbcsql17 -y
echo "mssqlODBCdriver install OK" >> $PREP_LOG
echo "Oracle ODBC driver installation" >> $PREP_LOG

wget https://www.datasunrise.com/support-files/oracle-instantclient19.10-basic-19.10.0.0.0-1.x86_64.rpm -O oracle-instantclient19.10-basic-19.10.0.0.0-1.x86_64.rpm
rpm -i oracle-instantclient19.10-basic-19.10.0.0.0-1.x86_64.rpm
# cd /opt/ds-cloud/oracle-instantclient19.10-basic-19.10.0.0.0-1
sudo ln -s libclntsh.so.12.1 libclntsh.so
echo logBeginAct "Oracle ODBC driver install OK" >> $PREP_LOG

az login --identity