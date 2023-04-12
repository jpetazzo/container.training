#!/bin/sh

case "$1-$2" in
linode-lb)
  linode-cli nodebalancers list --json | 
    jq '.[] | select(.label | startswith("ccm-")) | .id' | 
    xargs -n1 -P10 linode-cli nodebalancers delete
  ;;
linode-pvc)
  linode-cli volumes list --json | 
    jq '.[] | select(.label | startswith("pvc")) | .id' | 
    xargs -n1 -P10 linode-cli volumes delete
  ;;
digitalocean-lb)
  doctl compute load-balancer list --output json | 
    jq .[].id |
    xargs -n1 -P10 doctl compute load-balancer delete --force
  ;;
digitalocean-pvc)
  doctl compute volume list --output json |
    jq '.[] | select(.name | startswith("pvc-")) | .id' | 
    xargs -n1 -P10 doctl compute volume delete --force
  ;;
*)
  echo "Unknown combination of provider ('$1') and resource ('$2')."
  ;;
esac

