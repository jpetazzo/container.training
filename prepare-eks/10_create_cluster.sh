#!/bin/sh
eksctl create cluster \
    --node-type=t3.large \
    --nodes-max=10 \
    --alb-ingress-access \
    --asg-access \
    --ssh-access \
    --with-oidc \
    #

