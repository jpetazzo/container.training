#!/bin/sh
# Update the aws-auth ConfigMap to map our IAM users to Kubernetes users.
# Each user defined in "users.txt" will be mapped to a Kubernetes user
# with the same name, and put in the "container.training" group, too.
# This is idempotent.
# WARNING: this will wipe out the mapUsers component of the aws-auth
# ConfigMap, removing all users that aren't in "users.txt".
# It won't touch mapRoles, so it shouldn't break the role mappings
# put in place by EKS.

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

rm -f users.map
for U in $(cat users.txt); do
echo "\
- userarn: arn:aws:iam::$ACCOUNT:user/$U
  username: $U
  groups: [ container.training ]\
" >> users.map
done

kubectl create --namespace=kube-system configmap aws-auth \
  --dry-run=client --from-file=mapUsers=users.map -o yaml \
  | kubectl apply -f-
