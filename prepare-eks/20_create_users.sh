#!/bin/sh
# For each user listed in "users.txt", create an IAM user.
# Also create AWS API access keys, and store them in "users.keys".
# This is idempotent (you can run it multiple times, it will only
# create the missing users). However, it will not remove users.
# Note that you can remove users from "users.keys" (or even wipe
# that file out entirely) and then this script will delete their
# keys and generate new keys for them (and add the new keys to
# "users.keys".)

echo "Getting list of existing users ..."
aws iam list-users --output json | jq -r .Users[].UserName > users.tmp

for U in $(cat users.txt); do
    if ! grep -qw $U users.tmp; then
        echo "Creating user $U..."
        aws iam create-user --user-name=$U \
            --tags=Key=container.training,Value=1
    fi
    if ! grep -qw $U users.keys; then
        echo "Listing keys for user $U..."
        KEYS=$(aws iam list-access-keys --user=$U | jq -r .AccessKeyMetadata[].AccessKeyId)
        for KEY in $KEYS; do
            echo "Deleting key $KEY for user $U..."
            aws iam delete-access-key --user=$U --access-key-id=$KEY
        done
        echo "Creating access key for user $U..."
        aws iam create-access-key --user=$U --output json \
          | jq -r '.AccessKey | [ .UserName, .AccessKeyId, .SecretAccessKey ] | @tsv' \
          >> users.keys
    fi
done
