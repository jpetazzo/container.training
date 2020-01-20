#!/bin/sh
set -e
TAG=$(./workshopctl maketag)
./workshopctl start --settings settings/jerome.yaml --infra infra/aws-eu-central-1 --tag $TAG
./workshopctl deploy $TAG
./workshopctl kube $TAG
./workshopctl helmprom $TAG
while ! ./workshopctl kubetest $TAG; do sleep 1; done
./workshopctl tmux $TAG
echo ./workshopctl stop $TAG
