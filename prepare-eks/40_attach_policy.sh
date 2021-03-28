#!/bin/sh
# Attach our user policy to all the users defined in "users.txt".
# This should be idempotent, because attaching the same policy
# to the same user multiple times doesn't do anything.

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
POLICY_NAME=user.container.training

for U in $(cat users.txt); do
  echo "Attaching policy to user $U ..."
  aws iam attach-user-policy \
    --user-name $U \
    --policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME
done
