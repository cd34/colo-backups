#!/bin/bash

#DEVICE="colo1.mia.colo-cation.com"
#DEVICE="colo20.mia.colo-cation.com"
#DEVICE="c1ws1.mia.colo-cation.com"
#DEVICE="colo3.mia.colo-cation.com"
DEVICE="colo68.mia.colo-cation.com"

PATHS=`ssh -o StrictHostKeyChecking=no root@$DEVICE "grep -vE '(^(#|$)|(tmpfs|bind|swap|auto|proc)|/tmp)' /etc/fstab"`

IFS=`echo -en "\n\b"`
for dfline in $PATHS
do

  IFS=$' \t\n'
  fulldevice=${dfline%%[[:space:]]*}
  device=${fulldevice##*/}
  t=${dfline:${#fulldevice}}
  t2=${t#"${t%%[![:space:]]*}"}
  mntpoint=${t2%%[[:space:]]*}
  if [[ "$fulldevice" == UUID* ]]
  then
    device=${mntpoint#/}
    if [ -z "$device" ]
    then
      device='root'
    fi
  fi
echo "fd: $fulldevice dev: $device mp: $mntpoint"
exit;
done
