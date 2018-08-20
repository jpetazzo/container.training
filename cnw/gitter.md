# Gitter

## Setup

```bash
docker version
kubectl version
docker-compose version
```

```bash
git clone https://github.com/CloudNativeWales/container.training.git
```

## Docker

```bash
cd ~/container.training/dockercoins/
```

```bash
docker-compose up
```

```bash
docker-compose down
```

## Kubectl

```bash
kubectl get node
```

```bash
kubectl get nodes -o wide
kubectl get no -o yaml
```

```bash
kubectl get nodes -o json | jq ".items[] | {name:.metadata.name} + .status.capacity"
```

```bash
kubectl get services
```

```bash
curl -k https://10.96.0.1
```

```bash
kubectl get pods
```

```bash
kubectl get namespaces
```

```bash
kubectl -n kube-system get pods
```

```bash
kubectl -n kube-public get secrets
```

## Running our first containers on Kubernetes

```bash
kubectl run pingpong --image alpine ping 1.1.1.1
```

```bash
kubectl get all
```

```bash
kubectl logs deploy/pingpong
```

```bash
kubectl logs deploy/pingpong --tail 1 --follow
```

```bash
kubectl get pods -w
```

```bash
kubectl scale deploy/pingpong --replicas 8
```

```bash
kubectl delete pod pingpong-xxxxxxxxxx-yyyyy
```

```bash
kubectl logs -l run=pingpong --tail 1
```

## Exposing containers

```bash
kubectl run elastic --image=elasticsearch:2 --replicas=7
```

```bash
kubectl get pods -w
```

```bash
kubectl expose deploy/elastic --port 9200
```

```bash
kubectl get svc
```

```bash
IP=$(kubectl get svc elastic -o go-template --template '{{ .spec.clusterIP }}')
```

```bash
curl http://$IP:9200/
```

```bash
kubectl describe service elastic
```

```bash
kubectl get endpoints
```

```bash
kubectl describe endpoints elastic
```

```bash
kubectl get endpoints elastic -o yaml
```

```bash
kubectl get pods -l run=elastic -o wide
```

## Deploying a self-hosted registry

```bash
kubectl run registry --image=registry:2
```

```bash
kubectl expose deploy/registry --port=5000 --type=NodePort
```

```bash
kubectl describe svc/registry
```

```bash
NODEPORT=$(kubectl get svc/registry -o json | jq .spec.ports[0].nodePort)
REGISTRY=127.0.0.1:$NODEPORT
```

```bash
curl $REGISTRY/v2/_catalog
```

```bash
docker pull busybox
docker tag busybox $REGISTRY/busybox
```

```bash
docker push $REGISTRY/busybox
```

```bash
curl $REGISTRY/v2/_catalog
```

```bash
cd ~/container.training/stacks
```

```bash
export REGISTRY
export TAG=v0.1
docker-compose -f dockercoins.yml build
docker-compose -f dockercoins.yml push
```

```bash
kubectl run redis --image=redis
```

```bash
for SERVICE in hasher rng webui worker; do
  kubectl run $SERVICE --image=$REGISTRY/$SERVICE:$TAG
done
```

```bash
kubectl logs deploy/rng
```

```bash
kubectl logs deploy/worker
```

## Exposing services internally

```bash
kubectl expose deployment redis --port 6379
kubectl expose deployment rng --port 80
kubectl expose deployment hasher --port 80
```

```bash
kubectl logs deploy/worker --follow
```

## Exposing services for external access

```bash
kubectl expose deploy/webui --type=NodePort --port=80
```

```bash
kubectl get svc
```

## The Kubernetes dashboard

```bash
kubectl apply -f https://goo.gl/Qamqab
```

```bash
kubectl apply -f https://goo.gl/tA7GLz
```

```bash
kubectl -n kube-system get svc socat
```

```bash
kubectl apply -f https://goo.gl/CHsLTA
```

```bash
kubectl edit service kubernetes-dashboard
```

```bash
kubectl -n kube-system edit service kubernetes-dashboard
```

```bash
kubectl -n kube-system get services
```

## Scaling a deployment

```bash
kubectl get pods -w
```

```bash
kubectl get deployments -w
```

```bash
kubectl scale deploy/worker --replicas=10
```

## Daemon sets

```bash
kubectl get deploy/rng -o yaml --export >rng.yml
```

```bash
kubectl apply -f rng.yml
```

```bash
kubectl apply -f rng.yml --validate=false
```

```bash
kubectl logs -l run=rng --tail 1
```

```bash
kubectl describe deploy rng
```

```bash
kubectl describe rs rng-yyyy
kubectl describe rs -l run=rng
```

## Updating a service through labels and selectors

```bash
kubectl edit daemonset rng
```

```bash
kubectl edit service rng
```

```bash
kubectl logs -l run=rng --tail 1
```

```bash
kubectl get pods
```

```bash
kubectl get pods -l run=rng,isactive!=yes
```

```bash
kubectl delete pods -l run=rng,isactive!=yes
```

```bash
kubectl get pods
```

```bash
kubectl delete deployment rng
```

## Rolling updates

```bash
kubectl get deploy -o json | jq ".items[] | {name:.metadata.name} + .spec.strategy.rollingUpdate"
```

```bash
cd ~/container.training/stacks
```

```bash
export TAG=v0.2
docker-compose -f dockercoins.yml build
docker-compose -f dockercoins.yml push
```

```bash
kubectl get pods -w
kubectl get replicasets -w
kubectl get deployments -w
```

```bash
kubectl set image deploy worker worker=$REGISTRY/worker:$TAG
```

```bash
export TAG=v0.3
kubectl set image deploy worker worker=$REGISTRY/worker:$TAG
```

```bash
export TAG=v0.3
kubectl set image deploy worker worker=$REGISTRY/worker:$TAG
```

```bash
kubectl rollout status deploy worker
```

```bash
kubectl -n kube-system get svc socat
```

```bash
kubectl rollout undo deploy worker
kubectl rollout status deploy worker
```

```bash
kubectl patch deployment worker -p "
spec:
  template:
    spec:
      containers:
      - name: worker
        image: $REGISTRY/worker:v0.1
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  minReadySeconds: 10
"
```

```bash
kubectl rollout status deployment worker
```

```bash
kubectl get deploy -o json worker | jq "{name:.metadata.name} + .spec.strategy.rollingUpdate"
```

## Accessing logs from the CLI

```bash
sudo curl -L -o /usr/local/bin/stern \
   https://github.com/wercker/stern/releases/download/1.6.0/stern_linux_amd64
sudo chmod +x /usr/local/bin/stern
```

```bash
stern rng
```

```bash
stern --tail 1 --timestamps --all-namespaces weave
```

```bash
stern -l run
```

## Managing stacks with Helm

```bash
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
```

```bash
helm init
```

```bash
. <(helm completion $(basename $SHELL))
```

```bash
kubectl create clusterrolebinding add-on-cluster-admin \
  --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

```bash
helm search
```

```bash
helm search prometheus
```

```bash
helm install stable/prometheus \
     --set server.service.type=NodePort \
     --set server.persistentVolume.enabled=false
```

```bash
helm inspect stable/prometheus
```

```bash
helm create dockercoins
```

```bash
mv dockercoins/templates dockercoins/default-templates
mkdir dockercoins/templates
```

```bash
while read kind name; do
  kubectl get -o yaml --export $kind $name > dockercoins/templates/$name-$kind.yaml
done <<EOF
deployment worker
deployment hasher
daemonset rng
deployment webui
deployment redis
service hasher
service rng
service webui
service redis
EOF
```

```bash
helm install dockercoins
```

## Namespaces

```bash
kubectl create namespace blue
```

```bash
kubectl apply -f- <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: blue
EOF
```

```bash
kubectl -n blue get svc
```

```bash
kubectl config get-contexts
```

```bash
kubectl config set-context blue --namespace=blue \
  --cluster=kubernetes --user=kubernetes-admin
```

```bash
kubectl config use-context blue
```

```bash
helm install dockercoins
```

```bash
kubectl get svc webui
```