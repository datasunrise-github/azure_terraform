#!/bin/bash
DTF=`date '+%Y-%m-%d-%H-%M-%S'`
BACKUP_TMPDIR=$2
BACKUP_INP=$1
BACKUP_NAME_PREFIX=$3
if [ -z "$BACKUP_INP" ]; then
    exit 1
fi
if [ -z "$BACKUP_NAME_PREFIX" ]; then
    BACKUP_NAME_PREFIX=${BACKUP_INP##*/}
    if [ -z "$BACKUP_NAME_PREFIX" ]; then
        BACKUP_NAME_PREFIX=Generic
    fi
fi
BACKUP_NAME="${BACKUP_NAME_PREFIX}-backup-$DTF"
BACKUP_GZ=${BACKUP_NAME}.tar.gz
mkdir -p $BACKUP_TMPDIR
tar czfP $BACKUP_TMPDIR/$BACKUP_GZ $BACKUP_INP