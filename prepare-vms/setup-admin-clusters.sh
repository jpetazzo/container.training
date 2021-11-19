#!/bin/sh
set -e

export AWS_INSTANCE_TYPE=t3a.small

INFRA=infra/aws-eu-north-1

STUDENTS=2

PREFIX=$(date +%Y-%m-%d-%H-%M)

SETTINGS=admin-dmuc
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS

SETTINGS=admin-kubenet
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS

SETTINGS=admin-kuberouter
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS

INFRA=infra/enix

SETTINGS=admin-oldversion
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS

SETTINGS=admin-test
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS
