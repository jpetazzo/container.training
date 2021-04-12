#!/bin/sh
# Create an EKS cluster.
# This is not idempotent (each time you run it, it creates a new cluster).

eksctl create cluster \
    --node-type=t3.large \
    --nodes-max=10 \
    --alb-ingress-access \
    --asg-access \
    --ssh-access \
    --with-oidc \
    #

