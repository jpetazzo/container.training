#!/bin/sh
set -e

TIME=$(which time)

PROVIDER=$1
[ "$PROVIDER" ] || {
  echo "Please specify a provider as first argument, or 'ALL' for parallel mode."
  echo "Available providers:"
  ls -1 source/modules
  exit 1
}

[ "$TAG" ] || {
  TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
  RANDOMTAG=$(base64 /dev/urandom | tr A-Z a-z | tr -d /+ | head -c5)
  export TAG=tag-$TIMESTAMP-$RANDOMTAG
}

[ "$PROVIDER" = "ALL" ] && {
  for PROVIDER in $(ls -1 source/modules); do
    $TERMINAL -T $TAG-$PROVIDER -e sh -c "
      export TAG=$TAG-$PROVIDER
      $0 $PROVIDER
      cd $TAG-$PROVIDER
      bash
      " &
  done
  exit 0
}

[ -d "source/modules/$PROVIDER" ] || {
  echo "Provider '$PROVIDER' not found."
  echo "Available providers:"
  ls -1 source/modules
  exit 1  
}

export LINODE_TOKEN=$(grep ^token ~/.config/linode-cli | cut -d= -f2 | tr -d " ")
export DIGITALOCEAN_ACCESS_TOKEN=$(grep ^access-token ~/.config/doctl/config.yaml | cut -d: -f2 | tr -d " ")

cp -a source $TAG
cd $TAG
cp -r modules/$PROVIDER modules/PROVIDER
$TIME -o time.1.init terraform init
$TIME -o time.2.stage1 terraform apply -auto-approve
cd stage2
$TIME -o ../time.3.init terraform init
$TIME -o ../time.4.stage2 terraform apply -auto-approve
