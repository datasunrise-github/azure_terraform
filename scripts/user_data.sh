#!/bin/bash

export PREP_LOG=/var/log/cloud-init-output.log
echo "Configuration script has been started" >> $PREP_LOG
timedatectl set-timezone ${timeZone}

export CFS_BGN_TS=$(date +%s.%N)
export DSROOT=/opt/datasunrise
export DSCLOUDDIR=/opt/ds-cloud
export BackupUploadLog=/tmp/backup-upload.log
export BackupTempDir=/tmp/ds-backups
export AliveMetricName=ServiceAlive
export AliveMetricNamespace=DataSunrise
export AliveMetricLog=/tmp/send-alive.log

source /opt/cooked/ds_install.sh

mkdir -p $DSCLOUDDIR

mv /opt/cooked/* $DSCLOUDDIR/
rm -fR /opt/cooked

echo "DSAdminPassword exporting has been started"  >> $PREP_LOG
export DSAdminPassword=$DSAdminPassword

cd $DSCLOUDDIR
# DO NOT change order!
echo "ds_install execution"  >> $PREP_LOG
source ds_install.sh
echo "install_libraries execution" >> $PREP_LOG
source install_libraries.sh
echo "ds_pre_setup execution"  >> $PREP_LOG
source ds_pre_setup.sh
echo "ds-manip execution"  >> $PREP_LOG
source ds-manip.sh
echo "ds_setup execution"  >> $PREP_LOG
source ds_setup.sh

if [ -z "$HA_DBHOST" ] || [ -z "$HA_DBPORT" ]; then
    echo "Dictionary DB not found! Goodbye..." >> $PREP_LOG
    onAbortSetup
    exit $RETVAL
fi
if [ -z "$HA_AUHOST" ] || [ -z "$HA_AUPORT" ]; then
    echo "Audit DB not found! Goodbye..." >> $PREP_LOG
    onAbortSetup
    exit $RETVAL
fi

installProduct
if [ "$RETVAL" != "0" ]; then
    echo "Installation Error! Goodbye..." >> $PREP_LOG
    onAbortSetup
    exit $RETVAL
fi

# Installation OK, continue
makeItMine

echo "Setup DataSunrise..." >> $PREP_LOG
cd $DSROOT

FIRST_NODE=0
resetDict
setDictionaryLicense
if [ "$RETVAL" == "93" ]; then
    FIRST_NODE=1
    echo "Setup First Node of DataSunrise..." >> $PREP_LOG    
    resetAdminPassword
    
elif [ "$RETVAL" == "94" ]; then
    FIRST_NODE=0
    echo "Setup Next Node of DataSunrise..." >> $PREP_LOG
    
elif [ "$RETVAL" == "95" ]; then
    FIRST_NODE=0
    echo "Setup Next Node of DataSunrise..." >> $PREP_LOG
else
    echo "Setup Dictionary Error! Goodbye..." >> $PREP_LOG
    onAbortSetup
    exit $RETVAL
fi
resetAudit
if [ "$RETVAL" != "96" ]; then
    echo "Setup Audit Error! Goodbye..." >> $PREP_LOG
    onAbortSetup
    exit $RETVAL
fi
makeItMine
cleanLogs
service datasunrise start
sleep 20
checkInstanceExists
if [ "$instanceExists" == "0" ]; then
    echo "Create proxy..." >> $PREP_LOG
    setupProxy    
    setupCleaningTask
else
    echo "Copy proxy..." >> $PREP_LOG
    copyProxy
    runCleaningTask
fi

if [ "$FIRST_NODE" == "1" ]; then
	setupBackupParams
	setupAdditionals
fi

#setupBackupActions

service datasunrise stop
cleanLogs
makeItMine
configureKeepAlive
configureJVM
setcapAppFirewallCore
service datasunrise start

CFS_END_TS=$(date +%s.%N)
CFS_ELLAPSED=$(echo "$CFS_END_TS - $CFS_BGN_TS" | bc)
echo "Setup DataSunrise finished in $CFS_ELLAPSED sec."

uploadSetupLogs
fixfiles -FB onboot
sed -i 's/tmpfs \/dev\/shm tmpfs defaults,nodev,nosuid 0/tmpfs \/dev\/shm tmpfs defaults,nodev,nosuid,noexec 0/g' /etc/fstab
reboot