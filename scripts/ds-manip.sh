#!/bin/bash
makeItMineParam() {
    chown -R datasunrise:datasunrise "$1"
}
makeItMine() {
    chown -R datasunrise:datasunrise !(PortBinder|AppFirewallCore_Sniffer)
}
cleanLogs() {
    rm -f $DSROOT/logs/Backend*
    rm -f $DSROOT/logs/CoreLog*
    rm -f $DSROOT/logs/WebLog*
}
cleanSQLite() {
    rm -f $DSROOT/audit.db*
    rm -f $DSROOT/event.db*
    rm -f $DSROOT/dictionary.db*
    rm -f $DSROOT/local_settings.db*
    rm -f $DSROOT/lock.db*
}
loginToDS() {
    $DSROOT/cmdline/executecommand.sh connect -host 127.0.0.1 -login "$1" -password "$2"
    RETVAL=$?
}
logoutDS() {
    $DSROOT/cmdline/executecommand.sh disConnect -f
    RETVAL=$?
}
loginAsAdmin() {
    loginToDS admin "$DSAdminPassword"
}
