#!/bin/sh

JSON='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "eks:DescribeCluster"
            ],
            "Resource": "arn:aws:eks:*",
            "Effect": "Allow"
        }
    ]
}'

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

#aws iam create-policy --policy-name user.container.training --policy-document "$JSON"
aws iam create-policy-version --policy-arn arn:aws:iam::$ACCOUNT:policy/user.container.training --policy-document "$JSON" --set-as-default

# Uncomment this to check which users have the policy
#aws iam list-entities-for-policy --policy-arn arn:aws:iam::$ACCOUNT:policy/user.container.training
