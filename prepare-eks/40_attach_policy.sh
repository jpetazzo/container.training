#!/bin/sh

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

for U in $(cat users.txt); do
  echo "Attaching policy to user $U ..."
  aws iam attach-user-policy --user-name $U --policy-arn arn:aws:iam::$ACCOUNT:policy/user.container.training
done
