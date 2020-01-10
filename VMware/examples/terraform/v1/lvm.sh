#!/bin/bash
##this is the scrip to create pv, lv and mount the lv 
set -ex
vgchange -ay 
DEVICE_FS=`blkid -o value -s TYPE ${DEVICE} || echo ""`
if [ "`echo -n $DEVICE_FS`" == "" ] ; then
  # wait for the device to be attached
  DEVICENAME=`echo "${DEVICE}" | awk -F '/' '{print $3}'`
  DEVICEEXISTS=''
  while [[ -z $DEVICEEXISTS ]]; do
    echo "checking $DEVICENAME"
    DEVICEEXISTS=`lsblk |grep "$DEVICENAME" |wc -l`
    if [[ $DEVICEEXISTS != "1" ]]; then
      sleep 15
    fi
  done
  pvcreate ${DEVICE}
  vgcreate datavg ${DEVICE}
  lvcreate --name datalv -l 100%FREE datavg
  mkfs.ext4 /dev/datavg/datalv

fi
mkdir -p ${MOUNT_PATH}
echo '/dev/datavg/datalv  ${MOUNT_PATH}  ext4 defaults 0 0' >> /etc/fstab
mount ${MOUNT_PATH}