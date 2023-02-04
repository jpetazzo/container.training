#!/bin/sh
linode-cli nodebalancers list --json | 
  jq '.[] | select(.label | startswith("ccm-")) | .id' | 
  xargs -n1 -P10 linode-cli nodebalancers delete
