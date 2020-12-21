#!/bin/bash

while IFS=, read -r col1 col2
do
  echo "--> Deleting user $col1 with password $col2"
  echo "====> UAAC"
  uaac user delete $col1
  echo "====> Kubernetes"
  cat user-role-etc.yaml | sed "s/__username__/$col1/" | kubectl delete -f -
done < users.txt