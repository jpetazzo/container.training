#!/bin/sh
#
# Baseline resource usage per vcluster in our usecase:
# 500 MB RAM
# 10% CPU
# (See https://docs.google.com/document/d/1n0lwp6rQKQUIuo_A5LQ1dgCzrmjkDjmDtNj1Jn92UrI)
# PRO2-XS = 4 core, 16 gb

PROVIDER=scaleway

case "$PROVIDER" in
linode)
  export TF_VAR_node_size=g6-standard-6
  export TF_VAR_location=eu-west
  ;;
scaleway)
  export TF_VAR_node_size=PRO2-XS
  export TF_VAR_location=fr-par-2
  ;;
esac

./labctl create --mode mk8s --settings settings/konk.env --provider $PROVIDER --tag konk

# set kubeconfig file
export KUBECONFIG=~/kubeconfig
cp tags/konk/stage2/kubeconfig.101 $KUBECONFIG

# set external_ip labels
kubectl get nodes -o=jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="ExternalIP")].address}{"\n"}{end}' |
while read node address; do
  kubectl label node $node external_ip=$address
done

# vcluster all the things
./labctl create --settings settings/mk8s.env --provider vcluster --mode mk8s --students 50

# install prometheus stack because that's cool
helm upgrade --install --repo https://prometheus-community.github.io/helm-charts \
  --namespace prom-system --create-namespace \
  kube-prometheus-stack kube-prometheus-stack

# and also fix sysctl
kubectl apply -f ../k8s/sysctl.yaml --namespace kube-system
