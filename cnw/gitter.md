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

