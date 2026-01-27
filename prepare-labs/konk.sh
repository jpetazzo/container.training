#!/bin/sh
#
# Baseline resource usage per vcluster in our usecase:
# 500 MB RAM
# 10% CPU
# (See https://docs.google.com/document/d/1n0lwp6rQKQUIuo_A5LQ1dgCzrmjkDjmDtNj1Jn92UrI)
# PRO2-XS = 4 core, 16 gb
# Note that we also need 2 volumes per vcluster (one for vcluster itself, one for shpod),
# so we might hit the maximum number of volumes per node!
# (TODO: check what that limit is on Scaleway and Linode)
#
# With vspod:
# 800 MB RAM
# 33% CPU
#

set -e

KONKTAG=konk
PROVIDER=linode
STUDENTS=2

case "$PROVIDER" in
linode)
  export TF_VAR_node_size=g6-standard-6
  export TF_VAR_location=fr-par
  ;;
scaleway)
  export TF_VAR_node_size=PRO2-XS
  # For tiny testing purposes, these are okay too:
  #export TF_VAR_node_size=PLAY2-NANO
  export TF_VAR_location=fr-par-2
  ;;
esac

# set kubeconfig file
export KUBECONFIG=~/kubeconfig

if [ "$PROVIDER" = "kind" ]; then
  kind create cluster --name $KONKTAG
  ADDRTYPE=InternalIP
else
  if ! [ -f tags/$KONKTAG/stage2/kubeconfig.101 ]; then
    ./labctl create --mode mk8s --settings settings/konk.env --provider $PROVIDER --tag $KONKTAG
  fi
  cp tags/$KONKTAG/stage2/kubeconfig.101 $KUBECONFIG
  ADDRTYPE=ExternalIP
fi

# set external_ip labels
kubectl get nodes -o=jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="'$ADDRTYPE'")].address}{"\n"}{end}' |
while read node address ignoredaddresses; do
  kubectl label node $node external_ip=$address
done

# vcluster all the things
./labctl create --settings settings/mk8s.env --provider vcluster --mode mk8s --students $STUDENTS

# install prometheus stack because that's cool
helm upgrade --install --repo https://prometheus-community.github.io/helm-charts \
  --namespace prom-system --create-namespace \
  kube-prometheus-stack kube-prometheus-stack

# and also fix sysctl
kubectl apply -f ../k8s/sysctl.yaml --namespace kube-system
