#!/bin/sh

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

rm -f users.map
for U in ada.lovelace also.lol; do
echo "\
- userarn: arn:aws:iam::$ACCOUNT:user/$U
  username: $U
  groups: [ container.training ]\
" >> users.map
done

kubectl create --namespace=kube-system configmap aws-auth --dry-run=client --from-file=mapUsers=users.map -o yaml | kubectl apply -f-

