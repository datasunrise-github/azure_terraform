#!/bin/bash
get_key_from_storage_account(){
    az login --identity -o none
    key=$(az storage account keys list --account-name $BackupStorageName --resource-group $ResourceGroupStorage -o json --query [0].value | tr -d '"')
}

create_container() {
    get_key_from_storage_account
    containers="$(az storage container exists --account-name $BackupStorageName  --account-key $key --name deploying -o json --query "exists" | tr -d '"')"
    if [ $containers = "true" ]; then
        echo "The specified blob already exists."
    else
        az storage container create --name deploying --account-key $key --account-name $BackupStorageName
    fi
}

uploadSetupLogs() {
    if [ ! -z "$BackupStorageName" ]; then
        create_container
        az storage blob upload --account-key $key --file $CLOUD_INIT_LOG --name cloud-init-output.log --account-name $BackupStorageName -c deploying/$INST_ID --overwrite
    fi
}

uploadAllSetupLogs() {
    uploadSetupLogs
    if [ ! -z "$BackupStorageName" ]; then
        az storage blob sync --account-key $key -s $DSROOT/logs -c deploying/$INST_ID/dslogs --account-name $BackupStorageName
    fi
}