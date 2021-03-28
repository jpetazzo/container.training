#!/bin/sh
# Create an IAM policy to authorize users to do "aws eks update-kubeconfig".
# This is idempotent, which allows to update the policy document below if
# you want the users to do other things as well.
# Note that each time you run this script, it will actually create a new
# version of the policy, set that version as the default version, and
# remove all non-default versions. (Because you can only have up to
# 5 versions of a given policy, so you need to clean them up.)
# After running that script, you will want to attach the policy to our
# users (check the other scripts in that directory).

POLICY_NAME=user.container.training
POLICY_DOC='{
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

aws iam create-policy-version \
  --policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME \
  --policy-document "$POLICY_DOC" \
  --set-as-default

# For reference, the command below creates a policy without versioning:
#aws iam create-policy \
#--policy-name user.container.training \
#--policy-document "$JSON"

for VERSION in $(
  aws iam list-policy-versions \
    --policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME \
    --query 'Versions[?!IsDefaultVersion].VersionId' \
    --output text)
do
  aws iam delete-policy-version \
    --policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME \
    --version-id "$VERSION"
done

# For reference, the command below shows all users using the policy:
#aws iam list-entities-for-policy \
#--policy-arn arn:aws:iam::$ACCOUNT:policy/$POLICY_NAME
