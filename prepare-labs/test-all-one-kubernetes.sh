#!/bin/sh

# Note: if you want to run this multiple times (e.g. to create
# another set of clusters while a first one is still running)
# you should set the TF_VAR_cluster_name environment variable.

cd terraform/one-kubernetes

case "$1" in
  create)
    tmux has-session || tmux new-session -d
    for PROVIDER in *; do
      [ -f "$PROVIDER/common.tf" ] || continue
      tmux new-window -n $PROVIDER
      tmux send-keys -t $PROVIDER "
      cd $PROVIDER
      terraform init -upgrade
      /usr/bin/time --output /tmp/time.$PROVIDER --format '%e\n(%E)' terraform apply -auto-approve"
    done
    ;;
  kubeconfig)
    for PROVIDER in *; do
      [ -f "$PROVIDER/terraform.tfstate" ] || continue
      (
        echo "Writing /tmp/kubeconfig.$PROVIDER..."
        cd $PROVIDER
        terraform output -raw kubeconfig > /tmp/kubeconfig.$PROVIDER
      )
    done
    ;;
  destroy)
    for PROVIDER in *; do
      [ -f "$PROVIDER/terraform.tfstate" ] || continue
      (
        cd $PROVIDER
        terraform destroy -auto-approve &&
        rm -rf terraform.tfstate* .terraform*
      )
    done
    ;;
  *)
    echo "Please specify one of the following actions:"
    echo "create, kubeconfig, destroy."
    ;;
esac
