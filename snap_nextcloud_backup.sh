# Backup for Nextcloud
#
## VARIABLES
DATADIR=/media/nas/RAID-1/nextcloud/data  #by default
DESTDIR=/media/nas/RAID-1/nextcloud_backups_tgz

# How many snap backup do you want to keep?
NUMBCK='6'

## CONS
NAME=$(uname -n)
DATE=$(date +'%Y-%m-%d')
BCKDIR=/var/snap/nextcloud/common/backups/

## SUB
info()
{
	echo "${NAME}|$(date +'%Y-%m-%d %H:%M:%S INFO: ')${@}" 1>&2
} # end info

info "Checking Backup destination"
if [ -d ${DESTDIR} ];
then
    info "Destination exist"
else
    info "Creating destination folder"
    mkdir -p ${DESTDIR}/snap
    chmod -r 700 ${DESTDIR}
fi


# backup Nextcloud
info "Backing up Snap folder"
/snap/bin/nextcloud.export -abc
if [ $? -eq 0 ];
#if [[ 0 == 0 ]];
then
    LASTBCK=`ls -tr -1 ${BCKDIR} | tail -1`
    info "Archiving Snap confing backup"
#    mkdir -p ${DESTDIR}/snap/${LASTBCK}/
#    chmod -r 700  ${DESTDIR}/snap/${LASTBCK}
#    tar -zcf ${DESTDIR}/snap/${LASTBCK}/${LASTBCK}\.tar.gz ${BCKDIR}/${LASTBCK}
    tar -zcf ${DESTDIR}/snap/${LASTBCK}\.tar.gz ${BCKDIR}/${LASTBCK}

    info "Removing local backup"
#    rm -Rf ${BCKDIR}/${LAST}
else
    info "Nextcloud export failed, exiting..."
    exit 1
fi

info " rotate snap backup, keep last ${NUMBCK}"
ls -tp ${BCKDIR} | tail -n +$((${NUMBCK} + 1 )) | xargs -I {} rm -rf -- ${BCKDIR}{}
info ${NUMBCK} "IS Keeped"
info " backup Data"
if [ -d ${DATADIR} ];
then
    cd ${DATADIR}
    info "Stopping Nextcloud"
    snap stop nextcloud
    info "Backing up Data folder"
    rsync -azP --delete ${DATADIR} ${DESTDIR}
    info "Starting Nextcloud"
    snap start nextcloud
else
    info "Data Directory doesn't exist, exiting..."
    exit 1
fi

info " rotate snap backup, keep last ${NUMBCK}"
ls -tp ${DESTDIR}/snap/ | tail -n +$((${NUMBCK} + 1 )) | xargs -I {} rm -rf -- ${DESTDIR}/snap/{}
info ${NUMBCK} "IS Keeped"

info "Backup Completed on " ${DESTDIR}
