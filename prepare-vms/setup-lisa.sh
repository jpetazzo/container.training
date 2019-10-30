#!/bin/sh
set -e

export AWS_INSTANCE_TYPE=t3a.small

INFRA=infra/aws-us-west-2

STUDENTS=120

PREFIX=$(date +%Y-%m-%d-%H-%M)

SETTINGS=jerome
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

./workshopctl deploy $TAG
./workshopctl disabledocker $TAG
./workshopctl kubebins $TAG
./workshopctl disableaddrchecks $TAG
./workshopctl cards $TAG

