#!/bin/sh
set -e

PREFIX=$(date +%Y-%m-%d-%H-%M)
PROVIDER=openstack/enix # aws also works
STUDENTS=2
#export TF_VAR_location=eu-north-1
export TF_VAR_node_size=S

SETTINGS=admin-dmuc
TAG=$PREFIX-$SETTINGS
./labctl create \
	--tag $TAG \
	--provider $PROVIDER \
	--settings settings/$SETTINGS.env \
	--students $STUDENTS

SETTINGS=admin-kubenet
TAG=$PREFIX-$SETTINGS
./labctl create \
	--tag $TAG \
	--provider $PROVIDER \
	--settings settings/$SETTINGS.env \
	--students $STUDENTS

SETTINGS=admin-kuberouter
TAG=$PREFIX-$SETTINGS
./labctl create \
	--tag $TAG \
	--provider $PROVIDER \
	--settings settings/$SETTINGS.env \
	--students $STUDENTS

SETTINGS=admin-oldversion
TAG=$PREFIX-$SETTINGS
./labctl create \
	--tag $TAG \
	--provider $PROVIDER \
	--settings settings/$SETTINGS.env \
	--students $STUDENTS

SETTINGS=admin-test
TAG=$PREFIX-$SETTINGS
./labctl create \
	--tag $TAG \
	--provider $PROVIDER \
	--settings settings/$SETTINGS.env \
	--students $STUDENTS
