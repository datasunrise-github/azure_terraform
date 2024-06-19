#!/bin/bash
DSCLOUDDIR=$3
PROXY_CONF=$5
if [ ! -z "$PROXY_CONF" ]; then
    export HTTP_PROXY="$PROXY_CONF"
    export HTTPS_PROXY="$PROXY_CONF"
fi
BACKUP_TMPDIR=$4
BACKUP_BUCKET=$1
$BACKUP_CONTAINER=$2
if [ -z "$BACKUP_BUCKET" ]; then
    exit 1
fi

INST_ID=`curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/osProfile/computerName?api-version=2020-07-15&format=text"` 
uploadBackup() {
    echo -ne "Upload '$1'...\\n"
    # az login --identity
    az login --identity -o none
    az storage blob upload --account-key $key --file $BACKUP_TMPDIR/$BACKUP_GZ --name $BACKUP_GZ --account-name $BACKUP_BUCKET -c $BACKUP_CONTAINER/backup/$INST_ID
    uplrv=$?
    if [ $uplrv -eq 0 ]; then
        rm -f $1
    fi
}
goThrough() {
    for fent in $1/*
    do
        if [ -d "${fent}" ]; then
            goThrough $fent
        else
            if [ -f "${fent}" ]; then
                uploadBackup $fent
            fi
        fi
    done
}
goThrough $BACKUP_TMPDIR