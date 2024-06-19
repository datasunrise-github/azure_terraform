#!/bin/bash
setInstallationType() {
    echo "Setting up Installation Type for Azure..."
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService \
        CHANGE_SETTINGS=1 InstallationType=2
    RETVAL=$?
    echo "Setting up Installation Type for Azure result - $RETVAL"
}

resetAdminPassword() {
    echo "Reset Admin Password..." >> $PREP_LOG
    local DSAdminPassword=`az keyvault secret show --name ds-secret-admin-password --vault-name $DEPLOYMENTNAME-keyvault --query value --output tsv`
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService SET_ADMIN_PASSWORD=$DSAdminPassword
    RETVAL=$?
    echo $INST_CAPT: Reset DS Admin Password result - $RETVAL
}

resetDict() {
    local HA_DBTYPE_LWR="`echo "$HA_DBTYPE" | tr '[:upper:]' '[:lower:]'`"
    local HA_DBPASSWD="`az keyvault secret show --name ds-secret-config-password --vault-name $DEPLOYMENTNAME-keyvault --query value --output tsv`"
    echo "Reset Dictionary..." >> $PREP_LOG
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService CLEAN_LOCAL_SETTINGS PRINT_PROGRESS REMOVE_SERVER_BY_HOST_PORT=1 DICTIONARY_TYPE="$HA_DBTYPE_LWR" DICTIONARY_HOST="$HA_DBHOST" DICTIONARY_PORT="$HA_DBPORT" DICTIONARY_DB_NAME="$HA_DBNAME" DICTIONARY_LOGIN="$HA_DBUSER" DICTIONARY_PASS="$HA_DBPASSWD" FIREWALL_SERVER_NAME="$DS_SERVER" FIREWALL_SERVER_HOST="$DS_HOST_PRIVIP" FIREWALL_SERVER_BACKEND_PORT=11000 FIREWALL_SERVER_CORE_PORT=11001 FIREWALL_SERVER_BACKEND_HTTPS=1 FIREWALL_SERVER_CORE_HTTPS=1
    RETVAL=$?
    echo "Reset DS Dictionary to $HA_DBHOST:$HA_DBPORT result - $RETVAL" >> $PREP_LOG
}

resetAudit() {
    local HA_AUPASSWD="`az keyvault secret show --name ds-secret-config-password --vault-name $DEPLOYMENTNAME-keyvault --query value --output tsv`"
    echo "Reset Audit..." >> $PREP_LOG
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService CHANGE_SETTINGS AuditDatabaseType="$HA_AUTYPE" AuditDatabaseHost="$HA_AUHOST" AuditDatabasePort="$HA_AUPORT" AuditDatabaseName="$HA_AUNAME" AuditLogin="$HA_AUUSER" AuditPassword="$HA_AUPASSWD"
    RETVAL=$?
    echo "Reset DS Audit to $HA_AUHOST:$HA_AUPORT result - $RETVAL" >> $PREP_LOG
}

setupProxy() {
    local TRG_DBPASSWD="`az keyvault secret show --name tdb-secret-password --vault-name $DEPLOYMENTNAME-keyvault --query value --output tsv`"
    echo "Setup DS proxy $TRG_INSTNAME for $TRG_DBHOST:$TRG_DBPORT" >> $PREP_LOG
    loginAsAdmin
    if [ $RETVAL == 0 ]; then
        local XTRA_ARGS=
        local ENCRYPTION_ARGS=
        if [ "$TRG_DBTYPE" = "oracle" ] || [ "$TRG_DBTYPE" = "Oracle" ]; then
            XTRA_ARGS="-instance $TRG_DBNAME"
        elif [ "$TRG_DBTYPE" = "Elasticsearch" ] || [ "$TRG_DBTYPE" = "elasticsearch" ] ; then
            XTRA_ARGS="-protocolType HTTP -ssl"
        fi
        if [ "$TRG_ENCRYPTION" ] && [[ "$TRG_DBTYPE" =~ ^(Aurora MySQL|MySQL|MariaDB|Cassandra|DB2|DynamoDB|MongoDB|Oracle|oracle|SAP HANA)$ ]]; then
            ENCRYPTION_ARGS="-ssl"
        fi
        echo "addInstancePlus $TRG_INSTNAME..."
        $DSROOT/cmdline/executecommand.sh addInstancePlus -name "$TRG_INSTNAME" $XTRA_ARGS\
            -dbType "$TRG_DBTYPE" \
            -dbHost "$TRG_DBHOST" \
            -dbPort "$TRG_DBPORT" \
            -database "$TRG_DBNAME" \
            -login "$TRG_DBUSER" \
            -password "$TRG_DBPASSWD" \
            -proxyHost "$DS_HOST_PRIVIP" \
            -proxyPort "$TRG_DBPORT" \
            -savePassword azurekv \
            -azureKeyVault "$DEPLOYMENTNAME-keyvault" \
            -azureSecretName "tdb-secret-password"
            $ENCRYPTION_ARGS
        RETVAL=$?
        if [ $RETVAL == 0 ]; then
            echo "Add AuditRuleAdmin..."
            $DSROOT/cmdline/executecommand.sh addRule -action audit -name AuditRuleAdmin -logData true -filterType ddl -ddlSelectAll true -dbType "$TRG_DBTYPE" -instance "$TRG_INSTNAME"
            echo "Add AuditRuleDML..."
            $DSROOT/cmdline/executecommand.sh addRule -action audit -name AuditRuleDML -logData true -dbType "$TRG_DBTYPE" -instance "$TRG_INSTNAME"
            RETVAL=$?
        fi
    fi
    RETVAL=$?
    echo "Setup DS proxy $TRG_INSTNAME for $TDBHost:$TDBPort result - $RETVAL"
}

copyProxy() {
    echo "Starting copying proxies..." >> $PREP_LOG
    service datasunrise stop
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService COPY_PROXIES
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService COPY_TRAILINGS
    service datasunrise restart
    echo "Finished copying proxies" >> $PREP_LOG
}

checkInstanceExists() {
    echo "Checking existing instances..." >> $PREP_LOG
    loginAsAdmin
    instanceExists=
    local instances=`$DSROOT/cmdline/executecommand.sh showInstances`;
        if [[ "$instances" == "No Instances" ]]; then
            instanceExists=0
            echo "No instances found, returning 0." >> $PREP_LOG
            return 0
        else
            instanceExists=1
            echo "Instances found, returning 1." >> $PREP_LOG
            return 1
        fi
}

checkNeighbours(){
    echo "Checking neigbour instances from my scale set..." >> $PREP_LOG
    INST_ID=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/osProfile/computerName?api-version=2020-07-15&format=text"`
    local metadata=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -s)
    local VMSS_NAME=$(echo $metadata | jq -r '.compute.vmScaleSetName')
    local neighbours=$(az vmss list-instances --resource-group $DSRESOURCE_GROUP --name $VMSS_NAME --query "[]" -o json | python3 -c "import sys, json; instances = json.load(sys.stdin); result = [inst['osProfile']['computerName'] for inst in instances if inst['instanceId'] != '$INST_ID']; print(' '.join(result))")
    if [[ -z $neighbours ]]; then
        echo "No neighbours found, returning 0" >> $PREP_LOG
        return 0
    else
        echo "Neighbours found, returning 1" >> $PREP_LOG
        return 1
    fi
}

waitForRandTime(){
    echo "Waiting for random time..." >> $PREP_LOG
    sleep $(( RANDOM % 270 + 30 ));
    echo "Finished waiting" >> $PREP_LOG
}

processSetupOrCopy(){
  echo "Entered main setupProxy function. Will decide to create or to copy..." >> $PREP_LOG
  checkInstanceExists
  if [ $? == 1 ]; then
    copyProxy
  else
    checkNeighbours
    if [ $? == 0 ]; then
      setupProxy
    else
      waitForRandTime
      checkInstanceExists
      if [ $? == 1 ]; then
        copyProxy
      else
        setupProxy
        if [ $? -ne 0 ]; then
          copyProxy
        fi
      fi
    fi
  fi
  echo "Exited main setupProxy function." >> $PREP_LOG
}

setupBackupParams() {
    echo "Setup backups..." >> $PREP_LOG
    loginAsAdmin
    if [ $RETVAL == 0 ]; then
        echo "Setup OnDictionaryBackupDoneCommand..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name OnDictionaryBackupDoneCommand -value "$DSCLOUDDIR/backup-prepare.sh <backup_path> $BackupTempDir Dictionary"
        echo "Setup OnOldLogDeleteCommand..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name OnOldLogDeleteCommand -value "$DSCLOUDDIR/backup-prepare.sh <log_file> $BackupTempDir"
        RETVAL=$?
    fi
    echo "Setup backups result - $RETVAL" >> $PREP_LOG
}

setupBackupActions() {
    echo -ne "*/5 * * * * root $DSCLOUDDIR/backup-upload.sh $BackupStorageName $DSCLOUDDIR $BackupTempDir\n" | tee --append /etc/crontab
}

setupAdditionals() {
    echo "Setup additional parameters..." >> $PREP_LOG
    loginAsAdmin
    if [ $RETVAL == 0 ]; then
        echo "Setup WebLoadBalancerEnabled..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name WebLoadBalancerEnabled -value 1
        echo "Setup AuditDiscFreeSpaceLimit for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name AuditDiscFreeSpaceLimit -value 2048
        echo "Setup LogsDiscFreeSpaceLimit for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name LogsDiscFreeSpaceLimit -value 2048
        echo "Setup LogTotalSizeCore for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name LogTotalSizeCore -value 10000
        echo "Setup LogTotalSizeBackend for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name LogTotalSizeBackend -value 10000
		echo "Setup AuditPartitionEnable for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name AuditPartitionEnable -value 1
        echo "Setup AuditPartitionInterval for HA config..." >> $PREP_LOG
        $DSROOT/cmdline/executecommand.sh changeParameter -name AuditPartitionInterval -value 1
        RETVAL=$?
    fi
    echo "Setup additional parameters result - $RETVAL" >> $PREP_LOG
}

setupDSLicense() {
    az login --identity -o none
    echo "Setup license..." >> $PREP_LOG
    local DSLicenseKey="`az keyvault secret show --name ds-secret-licensekey --vault-name $DEPLOYMENTNAME-keyvault --query value --output tsv`"
    if [ -z "$DSLicenseKey" ]; then
        RETVAL=2
        echo "License key is EMPTY!" >> $PREP_LOG
        return $RETVAL
    fi
    echo "$DSLicenseKey" > /tmp/appfirewall.reg
    mv /tmp/appfirewall.reg $DSROOT/
    makeItMineParam $DSROOT/appfirewall.reg
    echo "Setup license result - $?" >> $PREP_LOG
}

onAbortSetup() {
    uploadAllSetupLogs
    makeItMine
    cleanLogs
    sudo service datasunrise stop
}

setupCleaningTask() {
    echo "Set node cleaning task..." >> $PREP_LOG
    loginAsAdmin
    if [ $RETVAL == 0 ]; then
        local CLEANING_PT_JSON="{\"id\":-1, \"enabled\": false, \"storePeriodType\":0,\"storePeriodValue\":0,\"name\":\"azure_remove_servers\",\"type\":32,\"lastExecTime\":\"\",\"nextExecTime\":\"\",\"lastSuccessTime\":\"\",\"lastErrorTime\":\"\",\"serverID\":0,\"forceUpdate\":false,\"params\":{},\"frequency\":{\"minutes\":{\"beginDate\":\"2018-09-28 00:00:00\",\"repeatEvery\":10}},\"updateNextExecTime\":true}"
        $DSROOT/cmdline/executecommand.sh arbitrary -function updatePeriodicTask -jsonContent "$CLEANING_PT_JSON"
        RETVAL=$?
    fi
    echo "Set node cleaning task - $RETVAL" >> $PREP_LOG
}

runCleaningTask() {
    echo "Run node cleaning task..." >> $PREP_LOG
    loginAsAdmin
    if [ $RETVAL -eq 0 ]; then
        VM_CLEANING_TASK_ID=$("$DSROOT/cmdline/executecommand.sh" arbitrary -function getPeriodicTaskList -jsonContent '{taskTypes:[32]}' | python3 -c "import sys, json; print(json.load(sys.stdin)['data'][1][0])")
        "$DSROOT/cmdline/executecommand.sh" arbitrary -function executePeriodicTaskManually -jsonContent "{\"id\":$VM_CLEANING_TASK_ID}"
        RETVAL=$?
    fi
    echo "Run node cleaning task - $RETVAL" >> $PREP_LOG
}

configureKeepAlive() {
    echo "net.ipv4.tcp_keepalive_time = 60" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_intvl = 10" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_probes = 6" | tee -a /etc/sysctl.conf
    sysctl -p -q
}

configureJVM() {
    echo "Configuring JVM..." >> $PREP_LOG
    jvmpath=$(find / -name libjvm.so 2>/dev/null)
    echo $jvmpath | tr " " "\n" | sed -e "s/libjvm.so//" > /etc/ld.so.conf.d/jvm.conf
    ldconfig
    echo "Configuring JVM result - $RETVAL" >> $PREP_LOG
}

setcapAppFirewallCore() {
    echo "Executing setcap on $DSROOT/AppFirewallCore" >> $PREP_LOG
    DS_VER=$($DSROOT/AppBackendService VERSION)
    DS_VER_MAJ=$(echo "$DS_VER" | cut -d '.' -f 1)
    DS_VER_MIN=$(echo "$DS_VER" | cut -d '.' -f 2)
    if [ $DS_VER_MAJ -ge 9 ]; then
        echo "No setcap required for $DS_VER" >> $PREP_LOG
    elif  [ $DS_VER_MAJ -eq 8 ] && [ $DS_VER_MIN -ge 1 ]; then
        echo "No setcap required for $DS_VER" >> $PREP_LOG
    else
        echo "Executing setcap" >> $PREP_LOG
        setcap 'cap_net_raw,cap_net_admin=eip cap_net_bind_service=ep' $DSROOT/AppFirewallCore
    fi
    echo "Execution finished. Exit code is - $?" >> $PREP_LOG
}

setDictionaryLicense() {
    dsversion=`$DSROOT/AppBackendService VERSION`
    if [ '6.3.1.99999' = "`echo -e "6.3.1.99999\n$dsversion" | sort -V | head -n1`" ] ; then
        echo "DS Version is higher than 6.3.1.99999: $dsversion, setting license to dictionary..." >> $PREP_LOG
        LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService IMPORT_LICENSE_FROM_FILE=$DSROOT/appfirewall.reg
        echo "License has been set with exit code $?" >> $PREP_LOG
    fi
}
