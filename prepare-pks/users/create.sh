#!/bin/bash

while IFS=, read -r col1 col2
do
  echo "--> Adding user $col1 with password $col2"
  echo "====> UAAC"
  uaac user add $col1 --emails $col1@pks -p $col2
  echo "====> Kubernetes"
  cat user-role-etc.yaml | sed "s/__username__/$col1/" | kubectl apply -f -
done < users.txt
