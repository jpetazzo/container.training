# Exposing containers

- We can connect to our pods using their IP address

- Then we need to figure out a lot of things:

  - how do we look up the IP address of the pod(s)?

  - how do we connect from outside the cluster?

  - how do we load balance traffic?

  - what if a pod fails?

- Kubernetes has a resource type named *Service*

- Services address all these questions!

---

## ⚠️ Heads up!

- We're going to connect directly to pods and services, using internal addresses

- This will only work:

  - if you're attending a live class with our special lab environment

  - or if you're using our dev containers within codespaces

- If you're using a "normal" Kubernetes cluster (including minikube, KinD, etc):

  *you will not be able to access these internal addresses directly!*

- In that case, we suggest that you run an interactive container, e.g.:
  ```bash
  kubectl run --rm -ti --image=archlinux myshell
  ```

- ...And each time you see a `curl` or `ping` command run it in that container instead

---

class: extra-details

## But, why?

- Internal addresses are only reachable from within the cluster

  (=from a pod, or when logged directly inside a node)

- Our special lab environments and our dev containers let us do it anyways

  (because it's nice and convenient when learning Kubernetes)

- But that doesn't work on "normal" Kubernetes clusters

- Instead, we can use [`kubectl port-forward`][kubectl-port-forward] on these clusters

[kubectl-port-forward]: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/

---

## Running containers with open ports

- Let's run a small web server in a container

- We are going to use `jpetazzo/color`, a tiny HTTP server written in Go

- `jpetazzo/color` listens on port 80

- It serves a page showing the pod's name

  (this will be useful when checking load balancing behavior)

- We could also use the `nginx` official image instead

  (but we wouldn't be able to tell the backends from each other)

---

## Running our HTTP server

- We will create a deployment with `kubectl create deployment`

- This will create a Pod running our HTTP server

.lab[

- Create a deployment named `blue`:
  ```bash
  kubectl create deployment blue --image=jpetazzo/color
  ```

]

---

## Connecting to the HTTP server

- Let's connect to the HTTP server directly

  (just to make sure everything works fine; we'll add the Service later)

.lab[

- Get the IP address of the Pod:
  ```bash
  kubectl get pods -o wide
  ```

- Send an HTTP request to the Pod:
  ```bash
  curl http://`IP-ADDRESS`
  ```

]

You should see a response from the Pod.

---

## The Pod doesn't have a "stable identity"

- The IP address that we used above isn't "stable"

  (if the Pod gets deleted, the replacement Pod will have a different address)

.lab[

- Check the IP addresses of running Pods:
  ```bash
  watch kubectl get pods -o wide
  ```

- Delete the Pod:
  ```bash
  kubectl delete pod `blue-xxxxxxxx-yyyyy`
  ```

- Check that the replacement Pod has a different IP address

]

---

## Services in a nutshell

- Services give us a *stable endpoint* to connect to a pod or a group of pods

- An easy way to create a service is to use `kubectl expose`

- If we have a deployment named `my-little-deploy`, we can run:

  `kubectl expose deployment my-little-deploy --port=80`

  ... and this will create a service with the same name (`my-little-deploy`)

- Services are automatically added to an internal DNS zone

  (in the example above, our code can now connect to http://my-little-deploy/)

---

## Exposing our deployment

- Let's create a Service for our Deployment

.lab[

- Expose the HTTP port of our server:
  ```bash
  kubectl expose deployment blue --port=80
  ```

- Look up which IP address was allocated:
  ```bash
  kubectl get service
  ```

]

- By default, this created a `ClusterIP` service

  (we'll discuss later the different types of services)

---

class: extra-details

## Services are layer 4 constructs

- Services can have IP addresses, but they are still *layer 4*

  (i.e. a service is not just an IP address; it's an IP address + protocol + port)

- As a result: you *have to* indicate the port number for your service

  (with some exceptions, like `ExternalName` or headless services, covered later)

---

## Testing our service

- We will now send a few HTTP requests to our Pod

.lab[

- Let's obtain the IP address that was allocated for our service, *programmatically:*
  ```bash
  CLUSTER_IP=$(kubectl get svc blue -o go-template='{{ .spec.clusterIP }}')
  ```

<!--
```hide kubectl wait deploy blue --for condition=available```
```key ^D```
```key ^C```
-->

- Send a few requests:
  ```bash
  for i in $(seq 10); do curl http://$CLUSTER_IP; done
  ```

]

---

## A *stable* endpoint

- Let's see what happens when the Pod has a problem

.lab[

- Keep sending requests to the Service address:
  ```bash
  while sleep 0.3; do curl -m1 http://$CLUSTER_IP; done
  ```

- Meanwhile, delete the Pod:
  ```bash
  kubectl delete pod `blue-xxxxxxxx-yyyyy`
  ```

]

- There might be a short interruption when we delete the pod...

- ...But requests will keep flowing after that (without requiring a manual intervention)

- The `-m1` option is here to specify a 1-second timeout

---

## Load balancing

- The Service will also act as a load balancer

  (if there are multiple Pods in the Deployment)

.lab[

- Scale up the Deployment:
  ```bash
  kubectl scale deployment blue --replicas=3
  ```

- Send a bunch of requests to the Service:
  ```bash
  for i in $(seq 20); do curl http://$CLUSTER_IP; done
  ```

]

- Our requests are load balanced across the Pods!

---

## DNS integration

- Kubernetes provides an internal DNS resolver

- The resolver maps service names to their internal addresses

- By default, this only works *inside Pods* (not from the nodes themselves)

.lab[

- Get a shell in a Pod:
  ```bash
  kubectl run --rm -it --image=archlinux test-dns-integration
  ```

- Try to resolve the `blue` Service from the Pod:
  ```bash
  curl blue
  ```

]

---

class: extra-details

## Under the hood...

- Let's check the content of `/etc/resolv.conf` inside a Pod

- It should look approximately like this:
  ```
  search default.svc.cluster.local svc.cluster.local cluster.local ...
  nameserver 10.96.0.10
  options ndots:5
  ```

- Let's break down what these lines mean...

---

class: extra-details

## `nameserver 10.96.0.10`

- This is the address of the DNS server used by programs running in the Pod

- The exact address might be different

  (this one is the default one when setting up a cluster with `kubeadm`)

- This address will correspond to a Service on our cluster

- Check what we have in `kube-system`:
  ```bash
  kubectl get services --namespace=kube-system
  ```

- There will typically be a service named `kube-dns` with that exact address

  (that's Kubernetes' internal DNS service!)

---

class: extra-details

## `search default.svc.cluster.local ...`

- This is the "search list"

- When a program tries to resolve `foo`, the resolver will try to resolve:

  `foo.default.svc.cluster.local` (if the Pod is in the `default` Namespace)

  `foo.svc.cluster.local`

  `foo.cluster.local`

  ...(the other entries in the search list)...

  `foo`

- As a result, if there is Service named `foo` in the Pod's Namespace, we obtain its address!

---

class: extra-details

## Do You Want To Know More?

- If you want even more details about DNS resolution on Kubernetes and Linux...

  check [this blog post][dnsblog]!

[dnsblog]: https://jpetazzo.github.io/2024/05/12/understanding-kubernetes-dns-hostnetwork-dnspolicy-dnsconfigforming/

---

## Advantages of services

- We don't need to look up the IP address of the pod(s)

  (we resolve the IP address of the service using DNS)

- There are multiple service types; some of them allow external traffic

  (e.g. `LoadBalancer` and `NodePort`)

- Services provide load balancing

  (for both internal and external traffic)

- Service addresses are independent from pods' addresses

  (when a pod fails, the service seamlessly sends traffic to its replacement)

???

:EN:- Accessing pods through services
:EN:- Service discovery and load balancing

:FR:- Exposer un service
:FR:- Le DNS interne de Kubernetes et la *service discovery*
