#!/bin/sh

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
BUCKET=container.training
ROLE_NAME=s3-reader-container-training
POLICY_NAME=s3-reader-container-training
POLICY_DOC=$(envsubst <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject*"
      ],
      "Resource": [
        "arn:aws:s3:::$BUCKET",
        "arn:aws:s3:::$BUCKET/*"
      ]
    }
  ]
}
EOF
)

aws iam create-policy \
--policy-name $POLICY_NAME \
--policy-doc "$POLICY_DOC"

aws s3 mb s3://container.training

echo "this is a public object" \
| aws s3 cp - s3://container.training/public.txt \
--acl public-read

echo "this is a private object" \
| aws s3 cp - s3://container.training/private.txt \
--acl private

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME
