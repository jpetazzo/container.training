#!/bin/sh
scw k8s cluster list -o json | 
  jq -r '.[] | select(.status=="'${STATE-creating}'") | .id'  | xargs -n1 scw k8s cluster delete
