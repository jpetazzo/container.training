#!/bin/sh
set -e

export AWS_INSTANCE_TYPE=t3a.small

INFRA=infra/aws-us-east-2

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

#INFRA=infra/aws-us-west-1

export AWS_INSTANCE_TYPE=t3a.medium

SETTINGS=admin-test
TAG=$PREFIX-$SETTINGS
./workshopctl start \
	--tag $TAG \
	--infra $INFRA \
	--settings settings/$SETTINGS.yaml \
	--students $STUDENTS
