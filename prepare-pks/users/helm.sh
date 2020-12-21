#!/bin/bash

while IFS=, read -r col1 col2
do

kubectl -n $col1 create serviceaccount tiller

kubectl -n $col1 create role tiller --verb '*' --resource '*'

kubectl -n $col1 create rolebinding tiller --role tiller --serviceaccount ${col1}:tiller

kubectl create clusterrole ns-tiller --verb 'get,list' --resource namespaces

kubectl create clusterrolebinding tiller --clusterrole ns-tiller --serviceaccount ${col1}:tiller

helm init --service-account=tiller --tiller-namespace=$col1

kubectl -n $col1 delete service tiller-deploy

kubectl -n $col1 patch deployment tiller-deploy --patch '
spec:
  template:
    spec:
      containers:
        - name: tiller
          ports: []
          command: ["/tiller"]
          args: ["--listen=localhost:44134"]
'

done < users.txt
