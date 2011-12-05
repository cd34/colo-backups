#!/bin/bash

FILE='/var/tmp/toclean'

while [ 1==1 ]; do
  if [ -f $FILE ]; then
    TOCLEAN=`head -n 1 $FILE`
    echo Removing $TOCLEAN
    `rm -rf $TOCLEAN`;
    
    loop=0
    unset DIRS
  
    for DIR in `cat $FILE`; do
      if [ "$DIR" != "$TOCLEAN" ]; then
        DIRS[$loop]=$DIR
        loop=$(($loop+1))
      fi
    done
  
    `rm -f $FILE`
    for DIR in ${DIRS[*]}; do
      echo $DIR >> $FILE
    done
  else
    break
  fi
done
