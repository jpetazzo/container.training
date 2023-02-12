#!/bin/sh
linode-cli volumes list --json | 
  jq '.[] | select(.label | startswith("pvc")) | .id' | 
  xargs -n1 -P10 linode-cli volumes delete
