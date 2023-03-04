#!/bin/sh
set -e

TIME=$(which time)

if [ -f ~/.config/doctl/config.yaml ]; then
  export DIGITALOCEAN_ACCESS_TOKEN=$(grep ^access-token ~/.config/doctl/config.yaml | cut -d: -f2 | tr -d " ")
fi

if [ -f ~/.config/linode-cli ]; then
  export LINODE_TOKEN=$(grep ^token ~/.config/linode-cli | cut -d= -f2 | tr -d " ")
fi

[ "$1" ] || {
  echo "Syntax:"
  echo ""
  echo "$0 <provider> <region> [how-many-clusters] [min-nodes] [max-nodes]"
  echo ""
  echo "Available providers:"
  ls -1 source/modules
  echo ""
  echo "Leave the region empty to show available regions for this provider."
  echo "You can also specify ALL as a provider to simultaneously provision"
  echo "many clusters on *each* provider for benchmarking purposes."
  echo ""
  exit 1
}

PROVIDER="$1"

[ "$2" ] || {
  "./source/modules/$PROVIDER/list_locations.sh"
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
cat >terraform.tfvars <<EOF
location = "$2"
how_many_clusters = ${3-1}
min_nodes_per_pool = ${4-2}
max_nodes_per_pool = ${5-4}
EOF
$TIME -o time.1.init terraform init
$TIME -o time.2.stage1 terraform apply -auto-approve
cd stage2
$TIME -o ../time.3.init terraform init
$TIME -o ../time.4.stage2 terraform apply -auto-approve
