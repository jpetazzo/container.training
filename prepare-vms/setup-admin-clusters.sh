#!/bin/sh
set -e

retry () {
	N=$1
	I=0
	shift

	while ! "$@"; do
		I=$(($I+1))
		if [ $I -gt $N ]; then
			echo "FAILED, ABORTING"
			exit 1
		fi
		echo "FAILED, RETRYING ($I/$N)"
	done
}

export AWS_INSTANCE_TYPE=t3a.small

INFRA=infra/aws-eu-west-3

STUDENTS=2

PREFIX=$(date +%Y-%m-%d-%H-%M)

SETTINGS=admin-dmuc
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $STUDENTS

retry 5 ./workshopctl deploy $TAG
retry 5 ./workshopctl disabledocker $TAG
retry 5 ./workshopctl kubebins $TAG
./workshopctl cards $TAG

SETTINGS=admin-kubenet
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

retry 5 ./workshopctl disableaddrchecks $TAG
retry 5 ./workshopctl deploy $TAG
retry 5 ./workshopctl kubebins $TAG
./workshopctl cards $TAG

SETTINGS=admin-kuberouter
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--count $((3*$STUDENTS))

retry 5 ./workshopctl disableaddrchecks $TAG
retry 5 ./workshopctl deploy $TAG
retry 5 ./workshopctl kubebins $TAG
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

retry 5 ./workshopctl deploy $TAG
retry 5 ./workshopctl kube $TAG 1.15.9
./workshopctl cards $TAG
