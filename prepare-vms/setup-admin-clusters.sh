#!/bin/sh
set -e

INFRA=infra/aws-eu-west-3

STUDENTS=2

TAG=admin-dmuc
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$TAG.yaml \
	--count $STUDENTS

./workshopctl deploy $TAG
./workshopctl disabledocker $TAG
./workshopctl kubebins $TAG
./workshopctl cards $TAG

TAG=admin-kubenet
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$TAG.yaml \
	--count $((3*$STUDENTS))

./workshopctl deploy $TAG
./workshopctl kubebins $TAG
./workshopctl disableaddrchecks $TAG
./workshopctl cards $TAG

TAG=admin-kuberouter
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$TAG.yaml \
	--count $((3*$STUDENTS))

./workshopctl deploy $TAG
./workshopctl kubebins $TAG
./workshopctl disableaddrchecks $TAG
./workshopctl cards $TAG

TAG=admin-test
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$TAG.yaml \
	--count $((3*$STUDENTS))

./workshopctl deploy $TAG
./workshopctl kube $TAG 1.13.5
./workshopctl cards $TAG
