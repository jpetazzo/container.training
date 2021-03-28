#!/bin/sh

# Note: if cluster was created without OIDC provider attached,
# you need to run the following command. It is idempotent.
#eksctl utils associate-iam-oidc-provider --cluster cluster-name-12341234 --approve

if [ "$1" ]; then
    CLUSTER="$1"
else
    echo "Please indicate cluster to use. Available clusters:"
    aws eks list-clusters --output table
    exit 1
fi

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
OIDC=$(aws eks describe-cluster --name $CLUSTER --query cluster.identity.oidc.issuer --output text | cut -d/ -f3-)
ROLE_NAME=s3-reader-container-training
TRUST_POLICY=$(envsubst <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT}:oidc-provider/${OIDC}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
            "${OIDC}:sub": ["system:serviceaccount:container-training:*"]
        }
      }
    }
  ]
}
EOF
)

aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY"

kubectl annotate serviceaccounts \
    --namespace container-training default \
    "eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT:role/$ROLE_NAME" \
    --overwrite
