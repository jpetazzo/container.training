#!/bin/sh

banner() {
  echo "# This file was generated with the script $0."
  echo "#"
}

create_namespace() {
  # 'helm template --namespace ... --create-namespace'
  # doesn't create the namespace, so we need to create it.
  # https://github.com/helm/helm/issues/9813
  echo ---
  kubectl create namespace kubernetes-dashboard \
          -o yaml --dry-run=client
  echo ---
}

add_namespace() {
  # 'helm template --namespace ...' doesn't add namespace information,
  # so we do it with this convenient filter instead.
  # https://github.com/helm/helm/issues/10737
  kubectl create -f- -o yaml --dry-run=client --namespace kubernetes-dashboard
}

(
  banner
  create_namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       --set "extraArgs={--enable-skip-login,--enable-insecure-login}" \
       --set metricsScraper.enabled=true \
       --set protocolHttp=true \
       --set service.type=NodePort \
       | add_namespace
  echo ---
  kubectl create clusterrolebinding kubernetes-dashboard:insecure \
          --clusterrole=cluster-admin \
          --serviceaccount=kubernetes-dashboard:kubernetes-dashboard \
          -o yaml --dry-run=client \
          #
) > dashboard-insecure.yaml

(
  banner
  create_namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       --set metricsScraper.enabled=true \
       | add_namespace
) > dashboard-recommended.yaml

(
  banner
  create_namespace
  helm template kubernetes-dashboard kubernetes-dashboard \
       --repo https://kubernetes.github.io/dashboard/ \
       --create-namespace --namespace kubernetes-dashboard \
       --set metricsScraper.enabled=true \
       --set service.type=NodePort \
       | add_namespace
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
