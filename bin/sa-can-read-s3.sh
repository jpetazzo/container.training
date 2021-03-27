#!/usr/bin/env bash
# I would like to demonstrate access to AWS resource (e.g. S3 bucket) from a pod. Idea:
# create a bucket, put two objects in it (one public, one private), then … I suppose I
# need to create a role with access to the private object, associate the role to a service
# account in k8s, find an image with the aws CLI (or some s3 client) in it … ?

set -euo pipefail

emit_describe_cluster_policy() {
    # Not used right now, but this permission is required in order to run `aws eks update-kubeconfig`:
    echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "eks:DescribeCluster"
            ],
            "Resource": "'"arn:aws:eks:${REGION}:${ACCOUNT_ID}:cluster/${CLUSTER_NAME}"'",
            "Effect": "Allow"
        }
    ]
}'
}

create_describe_cluster_policy() {
    local role_name="can-describe-cluster"
    aws iam create-policy \
        --policy-name can-describe-cluster \
        --description "Policy allowing to describe ${CLUSTER_NAME}" \
        --policy-document "$(emit_describe_cluster_policy)"

    aws iam attach-user-policy --role-name "${role_name}" --policy-arn "${S3_POLICY_ARN}"
}

emit_service_account_role_trust_policy() {
    local oidc_provider_arn key_prefix
    oidc_provider_arn="$(aws iam list-open-id-connect-providers | jq -r '.OpenIDConnectProviderList[0].Arn')"
    key_prefix="$(echo "${oidc_provider_arn}" | cut -f2- -d '/')"

    echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "'"${oidc_provider_arn}"'"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
            "'"${key_prefix}:sub"'": "system:serviceaccount:default:default"
        }
      }
    }
  ]
}'
}

associate_oidc_provider() {
    local issuer_url
    issuer_url="$(aws eks describe-cluster --name "${CLUSTER_NAME}" --query "cluster.identity.oidc.issuer" --output text)"
    if ! aws iam list-open-id-connect-providers | grep "${issuer_url}"; then
        eksctl utils associate-iam-oidc-provider --cluster "${CLUSTER_NAME}" --approve
    else
        echo "OIDC provider already associated"
    fi
}

create_role() {
    if ! _="$(aws iam get-role --role-name "${ROLE_NAME}")"; then
        aws iam create-role --role-name "${ROLE_NAME}" --description "Role for service account" --assume-role-policy-document "$(emit_service_account_role_trust_policy)"
    else
        echo "Role ${ROLE_NAME} already exists"
    fi
}

annotate_serviceaccount() {
    kubectl annotate serviceaccounts default -n default "role-arn=arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
}

checkit() {
    kubectl run --image amazon/aws-cli --attach --restart=Never --rm --wait=true herro -- s3 cp s3://"${BUCKET_NAME}"/top-sekret.txt -
}

update_kubeconfig() {
    aws eks update-kubeconfig --name "${CLUSTER_NAME}"
}

teardown() {
    # see also 'can-describe-cluster' policy, if created via create_describe_cluster_policy
    aws iam detach-role-policy --policy-arn "${S3_POLICY_ARN}" --role-name "${ROLE_NAME}"
    aws iam delete-role "${ROLE_NAME}"
}

create_and_populate_bucket() {
    if ! _="$(aws s3api get-bucket-acl --bucket "${BUCKET_NAME}")"; then
        aws s3api create-bucket --region "${REGION}" --bucket "${BUCKET_NAME}" --create-bucket-configuration "LocationConstraint=${REGION}"
    else
        echo "Bucket ${BUCKET_NAME} already exists."
    fi
    f="$(mktemp)"
    echo "THE UNICORN IS IN THE GARDEN!!" >"${f}"
    aws s3api put-object --bucket "${BUCKET_NAME}" --key top-sekret.txt --body "${f}"
}

ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
S3_POLICY_ARN=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
CLUSTER_NAME=floral-mongoose-1616851817
ROLE_NAME=service-account-role
REGION=eu-north-1
BUCKET_NAME=wooga-booga-pants
export KUBECONFIG=myconfig

main() {
    if [ -n "${1:-}" ]; then
        echo "An argument was provided, running that: $1"
        "${1}"
    else
        echo "ACCOUNT_ID: $ACCOUNT_ID"
        associate_oidc_provider
        create_role
        aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${S3_POLICY_ARN}"
        annotate_serviceaccount
        checkit
    fi
}

main "$@"
