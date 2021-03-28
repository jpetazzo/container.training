#!/bin/sh
# Create an IAM role to be used by a Kubernetes ServiceAccount.
# The role isn't given any permissions yet (this has to be done by
# another script in this series), but a properly configured Pod
# should still be able to execute "aws sts get-caller-identity"
# and confirm that it's using that role.
# This requires the cluster to have an attached OIDC provider.
# This should be the case if the cluster has been created with
# the scripts in this directory; otherwise, this can be done with
# the subsequent command, which is idempotent:
# eksctl utils associate-iam-oidc-provider --cluster cluster-name-12341234 --approve
# The policy document used below will authorize all ServiceAccounts
# in the "container-training" Namespace to use that role.
# This script will also annotate the container-training:default
# ServiceAccount so that it can use that role.
# This script is not quite idempotent: if you want to use a new
# trust policy, some work will be required. (You can delete the role,
# but that requires detaching the associated policies. There might also
# be a way to update the trust policy directly; we didn't investigate this
# further at this point.)

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

exit

# Here are commands to delete the role:
for POLICY_ARN in $(aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[*].PolicyArn' --output text); do aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN; done
aws iam delete-role --role-name $ROLE_NAME

# Merging the policy with the existing policies:
{
aws iam get-role --role-name s3-reader-container-training | jq -r .Role.AssumeRolePolicyDocument.Statement[]
echo "$TRUST_POLICY" | jq -r .Statement[]
} | jq -s '{"Version": "2012-10-17", "Statement": .}' > /tmp/policy.json
aws iam update-assume-role-policy \
  --role-name $ROLE_NAME \
  --policy-document file:///tmp/policy.json
