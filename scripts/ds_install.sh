#!/bin/bash
mkdir -p /opt/cooked/
echo '#!/bin/bash' | sudo tee /opt/cooked/ds_install.sh
echo "
INST_ID=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/osProfile/computerName?api-version=2020-07-15&format=text"`
CLOUD_INIT_LOG=/var/log/cloud-init-output.log

export STACKNAME=\"${STACKNAME}\"
export DEPLOYMENTNAME=\"${DeploymentName}\"
REGION=\"${REGION}\"

DSDISTURL=\"${DSDISTURL}\"
DSLICTYPE=\"${DSLICTYPE}\"
DSAdminPassword=\"${DSAdminPassword}\"
DSCLOUDDIR=\"/opt/ds-cloud\"
DSROOT=\"/opt/datasunrise\"

DS_SERVER=\$INST_ID
DS_HOSTNAME=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/osProfile/computerName?api-version=2020-07-15&format=text"`
DS_HOST_PRIVIP=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text"`
AF_HOME=\$DSROOT
AF_CONFIG=\$AF_HOME

TRG_INSTNAME=\"DBInstance-${DeploymentName}\"
TRG_DBPASSWD=\"${TRG_DBPASSWD}\"
TRG_DBTYPE=\"${TRG_DBTYPE}\"
TRG_DBHOST=\"${TRG_DBHOST}\"
TRG_DBPORT=\"${TRG_DBPORT}\"
TRG_DBNAME=\"${TRG_DBNAME}\"
TRG_DBUSER=\"${TRG_DBUSER}\"
TRG_DBPROXYPORT=\"${TRG_DBPROXYPORT}\"

HA_DBHOST=\"${HA_DBHOST}\"
HA_DBPASSWD=\"${HA_DBPASSWD}\"
HA_DBTYPE=\"${HA_DBTYPE}\"
HA_DBPORT=\"${HA_DBPORT}\"
HA_DBNAME=\"${HA_DBNAME}\"
HA_DBUSER=\"${HA_DBUSER}\"
 
# 0 - Sqlite, 1 - PgSQL, 2 - MySQL, 3 - Redshift, 4 - Aurora
HA_AUPASSWD=\"${HA_AUPASSWD}\"
HA_AUTYPE=\"${HA_AUTYPE}\"
HA_AUHOST=\"${HA_AUHOST}\"
HA_AUPORT=\"${HA_AUPORT}\"
HA_AUNAME=\"${HA_AUNAME}\"
HA_AUUSER=\"${HA_AUUSER}\"

INST_CAPT=\"{$INST_ID}\" " | sudo tee -a /opt/cooked/ds_install.sh

#INST_ID=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text"`