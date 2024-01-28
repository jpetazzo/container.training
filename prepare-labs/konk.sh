#!/bin/sh

# deploy big cluster
#TF_VAR_node_size=g6-standard-6 \
#TF_VAR_nodes_per_cluster=5 \
#TF_VAR_location=eu-west \

TF_VAR_node_size=PRO2-XS \
TF_VAR_nodes_per_cluster=5 \
TF_VAR_location=fr-par-2 \
./labctl create --mode mk8s --settings settings/mk8s.env --provider scaleway --tag konk

# set kubeconfig file
cp tags/konk/stage2/kubeconfig.101 ~/kubeconfig

export KUBECONFIG=~/kubeconfig

# set external_ip labels
kubectl get nodes -o=jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="ExternalIP")].address}{"\n"}{end}' |
while read node address; do
  kubectl label node $node external_ip=$address
done

# vcluster all the things
./labctl create --settings settings/mk8s.env --provider vcluster --mode mk8s --students 50
