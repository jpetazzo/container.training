#!/bin/sh
# Create a shared Kubernetes Namespace ("container-training") as well as
# individual namespaces for every user in "users.txt", and set up a bunch
# of permissions.
# Specifically:
# - each user gets "view" permissions in the "default" Namespace
# - each user gets "edit" permissions in the "container-training" Namespace
# - each user gets permissions to list Nodes and Namespaces
# - each user gets "admin" permissions in their personal Namespace
# Note that since Kubernetes Namespaces can't have dots in their names,
# if a user has dots, dots will be mapped to dashes.
# So user "ada.lovelace" will get namespace "ada-lovelace".
# This is kind of idempotent (but will raise a bunch of errors for objects
# that already exist).
# TODO: if this needs to evolve, replace all the "create" operations by
# "apply" operations. But this is good enough for now.

kubectl create rolebinding --namespace default container.training \
  --group=container.training --clusterrole=view

kubectl create clusterrole view-nodes \
  --verb=get,list,watch --resource=node
kubectl create clusterrolebinding view-nodes \
  --group=container.training --clusterrole=view-nodes

kubectl create clusterrole view-namespaces \
  --verb=get,list,watch --resource=namespace
kubectl create clusterrolebinding view-namespaces \
  --group=container.training --clusterrole=view-namespaces

kubectl create namespace container-training
kubectl create rolebinding --namespace container-training edit \
  --group=container.training --clusterrole=edit

# Note: API calls to EKS tend to be fairly slow. To optimize things a bit,
# instead of running "kubectl" N times, we generate a bunch of YAML and
# apply it. It will still generate a lot of API calls but it's much faster
# than calling "kubectl" N times. It might be possible to make this even
# faster by generating a "kind: List" (I don't know if this would issue
# a single API calls or multiple ones; TBD!)
for U in $(cat users.txt); do
  NS=$(echo $U | tr . -)
  cat <<EOF
---
kind: Namespace
apiVersion: v1
metadata:
  name: $NS
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: $U
EOF
done | kubectl create -f-

