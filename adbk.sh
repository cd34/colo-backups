#!/bin/bash -x

DATE=`date +%Y%m%d%H`

loop=0
for f in `ls -d1 /colobk1/archive/*`
do
  DATEPATH=${f##*.}
  if [ "$DATEPATH" != "$DATE" ]
  then
    BDATES[$loop]=$DATEPATH
    loop=$(($loop+1))
  fi
done

CT=${#BDATES[*]}

if (( $CT > 0 ))
then
  RECENT=${BDATES[$(($CT-1))]}
  LINKDESTA=" --link-dest=/colobk1/archive/ads.$RECENT/"
  LINKDESTN=" --link-dest=/colobk1/archive/network.$RECENT/"
fi

/usr/bin/rsync -aplx $LINKDESTA root@[fd00:cd34:c010::d:34]:/var/www/juicyads.com/ads/ /colobk1/archive/ads.$DATE/
/usr/bin/rsync -aplx $LINKDESTN root@[fd00:cd34:c010::d:34]:/var/www/juicyads.com/network/ /colobk1/archive/network.$DATE/
