#!/bin/sh

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

for VERSION in $(aws iam list-policy-versions --policy-arn arn:aws:iam::$ACCOUNT:policy/user.container.training | jq -r '.Versions[].VersionId'); do
  aws iam delete-policy-version --policy-arn arn:aws:iam::$ACCOUNT:policy/user.container.training --version-id "$VERSION"
done
