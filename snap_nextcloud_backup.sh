#!/bin/bash
# Backup for Nextcloud
echo "Backups of nextcloud data and apps is started" | mail -s "Backups of nextcloud" mail@gmail.com # for sendin mail you can use postfix for example
#exec 1>/path to log file/backup.log
#exec 2>/path to erors of backup/ERRORS.log
#
## VARIABLES
DATADIR=/full path to data dir/data  #by default
DESTDIR=/full path to destination dir/nextcloud_backups_tgz

# How many snap backup do you want to keep?
NUMBCK='3'

## CONS
NAME=$(uname -n)
DATE=$(date +'%Y-%m-%d')
BCKDIR=/var/snap/nextcloud/common/backups

## SUB
info()
{
        echo "${NAME}|$(date +'%Y-%m-%d %H:%M:%S INFO: ')${@}" 1>&2
} # end info

echo "Checking Backup destination"
if [ -d ${DESTDIR} ];
then
    echo "Destination exist"
else
    echo "Creating destination folder"
    mkdir -p ${DESTDIR}/snap
    chmod -r 700 ${DESTDIR}
fi


# backup Nextcloud
echo "Backing up Snap folder run nextcloud.export -abc"
/snap/bin/nextcloud.export -abc
if [ $? -eq 0 ];
then
    LASTBCK=`ls -tr -1 ${BCKDIR} | tail -1`
    echo "Archiving Snap confing backup"
    tar cvpzf ${DESTDIR}/snap/${LASTBCK}\.tgz ${BCKDIR}/${LASTBCK}

    echo "Removing local backup"
#    rm -Rf ${BCKDIR}/${LAST} # if you uncoment thet, you removing backups dir evry time. i do the simlink on /var/snap/nextcloud/common/backups to external drive
else
    info "Nextcloud export failed, exiting..."
    exit 1
fi

echo " rotate snap backup, keep last ${NUMBCK}"
ls -tp ${BCKDIR} | tail -n +$((${NUMBCK} + 1 )) | xargs -I {} rm -rf -- ${BCKDIR}/{}
echo ${NUMBCK} "IS Keeped"
echo " backup Data"
if [ -d ${DATADIR} ];
then
    cd ${DATADIR}
    echo "Stopping Nextcloud"
    snap stop nextcloud
    echo "Backing up Data folder"
    rsync -azP --delete --progress ${DATADIR} ${DESTDIR}
    echo "Starting Nextcloud"
    snap start nextcloud
else
    info "Data Directory doesn't exist, exiting..."
    exit 1
fi

echo " rotate snap archined backup, keep last ${NUMBCK}"
ls -tp ${DESTDIR}/snap/ | tail -n +$((${NUMBCK} + 1 )) | xargs -I {} rm -- ${DESTDIR}/snap/{}
echo ${NUMBCK} "IS Keeped"

echo "Backup Completed on " ${DESTDIR}
#exec 0
echo "Backups of nextcloud data and apps was secessfull" | mail -s "Backups of nextcloud" mail@gmail.com
