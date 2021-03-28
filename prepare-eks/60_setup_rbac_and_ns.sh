#!/bin/sh
kubectl create rolebinding --namespace default container.training --group=container.training --clusterrole=view
kubectl create clusterrole view-nodes --verb=get,list,watch --resource=node
kubectl create clusterrolebinding view-nodes --group=container.training --clusterrole=view-nodes
kubectl create clusterrole view-namespaces --verb=get,list,watch --resource=namespace
kubectl create clusterrolebinding view-namespaces --group=container.training --clusterrole=view-namespaces

kubectl create namespace container-training
kubectl create rolebinding --namespace container-training edit --group=container.training --clusterrole=edit

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

