#!/bin/sh

banner() {
  echo "# This file was generated with the script $0."
  echo "#"
}

namespace() {
  # 'helm template --namespace ... --create-namespace'
  # doesn't create the namespace, so we need to create it.
  echo ---
  kubectl create namespace kubernetes-dashboard \
          -o yaml --dry-run=client
  echo ---
}

(
  banner
  namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       --set "extraArgs={--enable-skip-login,--enable-insecure-login}" \
       --set protocolHttp=true \
       --set service.type=NodePort \
       #
  echo ---
  kubectl create clusterrolebinding kubernetes-dashboard:insecure \
          --clusterrole=cluster-admin \
          --serviceaccount=kubernetes-dashboard:kubernetes-dashboard \
          -o yaml --dry-run=client \
          #
) > dashboard-insecure.yaml

(
  banner
  namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       #
) > dashboard-recommended.yaml

(
  banner
  namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       --set service.type=NodePort \
       #
  echo ---
  kubectl create clusterrolebinding kubernetes-dashboard:cluster-admin \
          --clusterrole=cluster-admin \
          --serviceaccount=kubernetes-dashboard:cluster-admin \
          -o yaml --dry-run=client \
          #
  echo ---
  kubectl create serviceaccount -n kubernetes-dashboard cluster-admin \
          -o yaml --dry-run=client \
          # 
) > dashboard-with-token.yaml
