#!/bin/sh
set -e

export AWS_INSTANCE_TYPE=t3a.small

INFRA=infra/aws-us-west-2

STUDENTS=2

PREFIX=$(date +%Y-%m-%d-%H-%M)

SETTINGS=admin-dmuc
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $STUDENTS

./workshopctl deploy $TAG
./workshopctl disabledocker $TAG
./workshopctl kubebins $TAG
./workshopctl cards $TAG

SETTINGS=admin-kubenet
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

./workshopctl disableaddrchecks $TAG
./workshopctl deploy $TAG
./workshopctl kubebins $TAG
./workshopctl cards $TAG

SETTINGS=admin-kuberouter
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

./workshopctl disableaddrchecks $TAG
./workshopctl deploy $TAG
./workshopctl kubebins $TAG
./workshopctl cards $TAG

#INFRA=infra/aws-us-west-1

export AWS_INSTANCE_TYPE=t3a.medium

SETTINGS=admin-test
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

./workshopctl deploy $TAG
./workshopctl kube $TAG 1.14.6
./workshopctl cards $TAG

