#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: ./random-names.sh 55"
  exit 1
fi

for i in {1..50}; do
   PW=`cat /dev/urandom | tr -dc 'a-zA-Z1-9' | fold -w 10 | head -n 1`
   echo "user$i,$PW"
done
