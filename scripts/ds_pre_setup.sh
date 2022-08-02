#!/bin/bash
installProduct() {
    RETVAL=0
    echo "Install DataSunrise..." >> $PREP_LOG
        DS_INSTALLER=DSCustomBuild.run

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
    chmod +x $DS_INSTALLER
    echo "Using binary: '$DS_INSTALLER'" >> $PREP_LOG
    local DS_INSTALLER_CMD="./$DS_INSTALLER --noprogress --target tmp install -f --no-password --no-start"
    $DS_INSTALLER_CMD
    RETVAL=$?
    echo "Result of '$DS_INSTALLER_CMD' is $RETVAL" >> $PREP_LOG
    if [ "$RETVAL" != "0" ]; then
        return $RETVAL
    fi
    echo "Remove: $DS_INSTALLER" >> $PREP_LOG
    rm -f $DS_INSTALLER
    local DSCLOUDDIR="${DSCLOUDDIR}"
    echo "Configuring SELinux support" >> $PREP_LOG
    make -f /usr/share/selinux/devel/Makefile
    semodule -i $DSCLOUDDIR/datasunrise.pp
    #sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
    ######################################################
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    setenforce 0
    restorecon -vRF /opt/datasunrise/ > /dev/null
    semanage port -a -t datasunrise_port_t -p tcp 11000-11010
    semanage port -a -t datasunrise_port_t -p tcp $TRG_DBPORT
    # semanage port -a -t datasunrise_port_t -p tcp $TRG_ADDITIONAL_INTERFACE_PORT
    echo "Adding ports to iptables" >> $PREP_LOG                                 
    iptables -A INPUT -p tcp --dport 11000:11010 -j ACCEPT
    iptables -A INPUT -p tcp --dport $TRG_DBPORT -j ACCEPT
    # iptables -A INPUT -p tcp --dport $TRG_ADDITIONAL_INTERFACE_PORT -j ACCEPT
    service iptables save
    echo "Setting sshd whitelist and blacklist" >> $PREP_LOG
    echo 'ALL: '`echo $SSHADMINCIDR | cut -d"/" -f1`'/'`ipcalc $SSHADMINCIDR -m | cut -d"=" -f2` >> /etc/hosts.allow
    sed -i 's/#ALL: ALL/ALL: ALL/g' /etc/hosts.deny
    echo "Turning on DataSunrise service" >> $PREP_LOG
    systemctl enable datasunrise
    echo "Turn on DataSunrise daemon" >> $PREP_LOG
    chkconfig datasunrise on
    local AF_GCNF=/etc/datasunrise.conf
    local ORACLE_HOME=/usr/lib/oracle/19.10/client64/lib
    echo "Setup $AF_GCNF..." >> $PREP_LOG
    echo "DS_SERVER_NAME_PREFIX=ds" | tee -a $AF_GCNF   
    echo "ORACLE_HOME=$ORACLE_HOME" | tee -a $AF_GCNF
    echo "DS configuration file $AF_GCNF" >> $PREP_LOG
    cat $AF_GCNF
    
    if [ "$DSLICTYPE" == "BYOL" ]; then
        echo "Setup BYOL licensing model..." >> $PREP_LOG
        setupDSLicense
    else
        echo "Setup Hourly Billing licensing model..." >> $PREP_LOG
        cp appfirewall-hb.reg /opt/datasunrise/appfirewall.reg
    fi
    makeItMine
    #cleanLogs
    cleanSQLite
    echo "Install DataSunrise result - $RETVAL" >> $PREP_LOG
}
