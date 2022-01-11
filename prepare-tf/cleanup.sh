#!/bin/sh
export LINODE_TOKEN=$(grep ^token ~/.config/linode-cli | cut -d= -f2 | tr -d " ")
export DIGITALOCEAN_ACCESS_TOKEN=$(grep ^access-token ~/.config/doctl/config.yaml | cut -d: -f2 | tr -d " ")
for T in  tag-*; do
(
  cd $T
  terraform apply -destroy -auto-approve && mv ../$T ../deleted$T
)
done
