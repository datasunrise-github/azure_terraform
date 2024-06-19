#!/bin/bash
installProduct() {
    RETVAL=0
    echo "Install DataSunrise..." >> $PREP_LOG
        DS_INSTALLER=DSCustomBuild.rpm

        wget --no-check-certificate -q -O $DS_INSTALLER  "$DSDISTURL" 

        if [[ "$?" != "0" ]]; then
                echo " Download was not successful, please check that URL is correct and available for downloading or AccessPolicy allows access to the bucket with the distribution file." >> $PREP_LOG
                echo " Installation will be interrupted." >> $PREP_LOG
                RETVAL=2
                return $RETVAL
        fi

    if [ -z "$DS_INSTALLER" ]; then
        echo "DataSunrise binary not found!" >> $PREP_LOG
        RETVAL=2
        return $RETVAL
    fi
    echo "Using binary: '$DS_INSTALLER'" >> $PREP_LOG
    # Installing additional libraries for DS
    # yum install libnsl -y
    local DS_INSTALLER_CMD="rpm -Uvh $DS_INSTALLER"
    $DS_INSTALLER_CMD
    RETVAL=$?
    echo "Result of '$DS_INSTALLER_CMD' is $RETVAL" >> $PREP_LOG
    if [ "$RETVAL" != "0" ]; then
        return $RETVAL
    fi
    echo "Remove: $DS_INSTALLER" >> $PREP_LOG
    rm -f $DS_INSTALLER
    configureLocalFirewallRules
    echo "Turning on DataSunrise service" >> $PREP_LOG
    systemctl enable datasunrise
    echo "Turn on DataSunrise daemon" >> $PREP_LOG
    # yum install chkconfig -y
    # chkconfig datasunrise on
    local AF_GCNF=/etc/datasunrise.conf
    local ORACLE_HOME=/usr/lib/oracle/21/client64/lib
    echo "Setup $AF_GCNF..." >> $PREP_LOG
    echo "DS_SERVER_NAME_PREFIX=ds" | tee -a $AF_GCNF
    echo "ORACLE_HOME=$ORACLE_HOME" | tee -a $AF_GCNF
    echo "DS configuration file $AF_GCNF" >> $PREP_LOG
    cat $AF_GCNF
    
    if [ "$DSLICTYPE" == "BYOL" ]; then
        echo "Setup BYOL licensing model..." >> $PREP_LOG
        setupDSLicense
    # else
    #     echo "Setup Hourly Billing licensing model..." >> $PREP_LOG
    #     cp appfirewall-hb.reg /opt/datasunrise/appfirewall.reg
    fi
    makeItMine
    #cleanLogs
    cleanSQLite
    echo "Install DataSunrise result - $RETVAL" >> $PREP_LOG
}

configureLocalFirewallRules(){
    echo "Temporarily Disable SELinux..."
    setenforce 0
    echo "Adding ports to firewalld..."
    firewall-cmd --add-port 11000-11010/tcp --zone public --permanent
    firewall-cmd --add-port $TRG_DBPORT/tcp --zone public --permanent
    firewall-cmd --complete-reload
    firewall-cmd --list-all
    echo "Enabling SELinux..."
    setenforce 1
}