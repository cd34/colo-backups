#!/bin/bash

DEVICE=$1
LOCALDEVICE=`echo $1 | sed s/.colo-cation.com$//`
BACKUPPATH=$2
REVISIONS="0$3"
ETH1DEVICE=$4

if [[ $DEVICE =~ [a-z0-9-]+ ]] ; then
  :
else
  echo Device $DEVICE is invalid
  exit -1
fi

BACKUP_DEVICE=$DEVICE
if [ $ETH1DEVICE ] ; then
  echo Backup of $DEVICE using $ETH1DEVICE starting...
  BACKUP_DEVICE=$ETH1DEVICE
else
  echo Backup of $DEVICE starting...
fi

if (( $REVISIONS < 2 ))
then
  REVISIONS=2
fi
REVISIONS=$(($REVISIONS*1))

DATE=`date +%Y%m%d`

RSYNC=/usr/bin/rsync

# get paths
PATHS=`ssh -o StrictHostKeyChecking=no root@$BACKUP_DEVICE "grep -vE '(^(#|$)|(tmpfs|bind|swap|auto|proc)|/tmp)' /etc/fstab"`

loop=0
for f in `ls -d1 $BACKUPPATH/$LOCALDEVICE/*`
do
  DATEPATH=${f##*/}
  if [ "$DATEPATH" != "$DATE" ]
  then
    BDATES[$loop]=$f
    loop=$(($loop+1))
  fi
done

CT=${#BDATES[*]}

if (( $CT > 0 )) 
then
  RECENT=${BDATES[$(($CT-1))]}
  LINKDEST=" --link-dest=$RECENT"
else 
  LINKDEST=""
fi

# # of Generations to store

mkdir -p $BACKUPPATH/$LOCALDEVICE/$DATE

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

  if [ -n "$LINKDEST" ]
  then
    DEST="$LINKDEST/$device/"
  fi
  $RSYNC -e 'ssh -o StrictHostKeyChecking=no' -aplxo --delete --exclude 'log/apache*' --exclude 'log/nginx/*' --exclude 'tmp/*' --exclude 'lock/*' --exclude 'lib/php[45]/*' --exclude 'weblogs/*' --exclude 'colocation/*' $DEST root@$BACKUP_DEVICE:$mntpoint/ $BACKUPPATH/$LOCALDEVICE/$DATE/$device/

done

if (( ${#BDATES[*]} >= $REVISIONS )) 
then
  DELFIRST=$(( ${#BDATES[*]} - $REVISIONS ))
  loop=0
  for d in ${BDATES[*]}
    do
      if (( $loop <= $DELFIRST ))
      then
#        `rm -rf $d`
        echo $d >> /var/tmp/toclean
      fi
      loop=$(($loop+1))
    done
fi
