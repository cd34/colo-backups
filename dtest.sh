#!/bin/bash -x

DEVICE="colo1.mia.colo-cation.com"
DEVICE="cAlo1.mia.colo-cation.com"
DEVICE="/"
DEVICE=""

if [[ $DEVICE =~ [a-z0-9-]+ ]] ; then
  :
else
  echo "broken"
  exit -1
fi

echo "outside the if"
