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

## Services in a nutshell

- Services give us a *stable endpoint* to connect to a pod or a group of pods

- An easy way to create a service is to use `kubectl expose`

- If we have a deployment named `my-little-deploy`, we can run:

  `kubectl expose deployment my-little-deploy --port=80`

  ... and this will create a service with the same name (`my-little-deploy`)

- Services are automatically added to an internal DNS zone

  (in the example above, our code can now connect to http://my-little-deploy/)

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

---

## Many kinds and flavors of service

- There are different types of services:

  `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`

- There are also *headless services*

- Services can also have optional *external IPs*

- There is also another resource type called *Ingress*

  (specifically for HTTP services)

- Wow, that's a lot! Let's start with the basics ...

---

## `ClusterIP`

- It's the default service type

- A virtual IP address is allocated for the service

  (in an internal, private range; e.g. 10.96.0.0/12)

- This IP address is reachable only from within the cluster (nodes and pods)

- Our code can connect to the service using the original port number

- Perfect for internal communication, within the cluster

---

class: pic
![](images/kubernetes-services/11-CIP-by-addr.png)

---

class: pic
![](images/kubernetes-services/12-CIP-by-name.png)

---

class: pic
![](images/kubernetes-services/13-CIP-both.png)

---

class: pic
![](images/kubernetes-services/14-CIP-headless.png)

---

## `LoadBalancer`

- An external load balancer is allocated for the service

  (typically a cloud load balancer, e.g. ELB on AWS, GLB on GCE ...)

- This is available only when the underlying infrastructure provides some kind of
  "load balancer as a service"

- Each service of that type will typically cost a little bit of money

  (e.g. a few cents per hour on AWS or GCE)

- Ideally, traffic would flow directly from the load balancer to the pods

- In practice, it will often flow through a `NodePort` first

---

class: pic
![](images/kubernetes-services/31-LB-no-service.png)

---

class: pic
![](images/kubernetes-services/32-LB-plus-cip.png)

---

class: pic
![](images/kubernetes-services/33-LB-plus-lb.png)

---

class: pic
![](images/kubernetes-services/34-LB-internal-traffic.png)

---

class: pic
![](images/kubernetes-services/35-LB-pending.png)

---

class: pic
![](images/kubernetes-services/36-LB-ccm.png)

---

class: pic
![](images/kubernetes-services/37-LB-externalip.png)

---

class: pic
![](images/kubernetes-services/38-LB-external-traffic.png)

---

class: pic
![](images/kubernetes-services/39-LB-all-traffic.png)

---

class: pic
![](images/kubernetes-services/41-NP-why.png)

---

class: pic
![](images/kubernetes-services/42-NP-how-1.png)

---

class: pic
![](images/kubernetes-services/43-NP-how-2.png)

---

class: pic
![](images/kubernetes-services/44-NP-how-3.png)

---

class: pic
![](images/kubernetes-services/45-NP-how-4.png)

---

class: pic
![](images/kubernetes-services/46-NP-how-5.png)

---

class: pic
![](images/kubernetes-services/47-NP-only.png)

---

## `NodePort`

- A port number is allocated for the service

  (by default, in the 30000-32767 range)

- That port is made available *on all our nodes* and anybody can connect to it

  (we can connect to any node on that port to reach the service)

- Our code needs to be changed to connect to that new port number

- Under the hood: `kube-proxy` sets up a bunch of `iptables` rules on our nodes

- Sometimes, it's the only available option for external traffic

  (e.g. most clusters deployed with kubeadm or on-premises)

---

## Running containers with open ports

- Since `ping` doesn't have anything to connect to, we'll have to run something else

- We could use the `nginx` official image, but ...

  ... we wouldn't be able to tell the backends from each other!

- We are going to use `jpetazzo/color`, a tiny HTTP server written in Go

- `jpetazzo/color` listens on port 80

- It serves a page showing the pod's name

  (this will be useful when checking load balancing behavior)

---

## Creating a deployment for our HTTP server

- We will create a deployment with `kubectl create deployment`

- Then we will scale it with `kubectl scale`

.lab[

- In another window, watch the pods (to see when they are created):
  ```bash
  kubectl get pods -w
  ```

<!--
```wait NAME```
```tmux split-pane -h```
-->

- Create a deployment for this very lightweight HTTP server:
  ```bash
  kubectl create deployment blue --image=jpetazzo/color
  ```

- Scale it to 10 replicas:
  ```bash
  kubectl scale deployment blue --replicas=10
  ```

]

---

## Exposing our deployment

- We'll create a default `ClusterIP` service

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

---

## Services are layer 4 constructs

- You can assign IP addresses to services, but they are still *layer 4*

  (i.e. a service is not an IP address; it's an IP address + protocol + port)

- This is caused by the current implementation of `kube-proxy`

  (it relies on mechanisms that don't support layer 3)

- As a result: you *have to* indicate the port number for your service
    
  (with some exceptions, like `ExternalName` or headless services, covered later)

---

## Testing our service

- We will now send a few HTTP requests to our pods

.lab[

- Let's obtain the IP address that was allocated for our service, *programmatically:*
  ```bash
  IP=$(kubectl get svc blue -o go-template --template '{{ .spec.clusterIP }}')
  ```

<!--
```hide kubectl wait deploy blue --for condition=available```
```key ^D```
```key ^C```
-->

- Send a few requests:
  ```bash
  curl http://$IP:80/
  ```

]

--

Try it a few times! Our requests are load balanced across multiple pods.

---

class: extra-details

## `ExternalName`

- Services of type `ExternalName` are quite different

- No load balancer (internal or external) is created

- Only a DNS entry gets added to the DNS managed by Kubernetes

- That DNS entry will just be a `CNAME` to a provided record

Example:
```bash
kubectl create service externalname k8s --external-name kubernetes.io
```
*Creates a CNAME `k8s` pointing to `kubernetes.io`*

---

class: extra-details

## External IPs

- We can add an External IP to a service, e.g.:
  ```bash
  kubectl expose deploy my-little-deploy --port=80 --external-ip=1.2.3.4
  ```

- `1.2.3.4` should be the address of one of our nodes

  (it could also be a virtual address, service address, or VIP, shared by multiple nodes)

- Connections to `1.2.3.4:80` will be sent to our service

- External IPs will also show up on services of type `LoadBalancer`

  (they will be added automatically by the process provisioning the load balancer)

---

class: extra-details

## Headless services

- Sometimes, we want to access our scaled services directly:

  - if we want to save a tiny little bit of latency (typically less than 1ms)

  - if we need to connect over arbitrary ports (instead of a few fixed ones)

  - if we need to communicate over another protocol than UDP or TCP

  - if we want to decide how to balance the requests client-side

  - ...

- In that case, we can use a "headless service"

---

class: extra-details

## Creating a headless services

- A headless service is obtained by setting the `clusterIP` field to `None`

  (Either with `--cluster-ip=None`, or by providing a custom YAML)

- As a result, the service doesn't have a virtual IP address

- Since there is no virtual IP address, there is no load balancer either

- CoreDNS will return the pods' IP addresses as multiple `A` records

- This gives us an easy way to discover all the replicas for a deployment

---

class: extra-details

## Services and endpoints

- A service has a number of "endpoints"

- Each endpoint is a host + port where the service is available

- The endpoints are maintained and updated automatically by Kubernetes

.lab[

- Check the endpoints that Kubernetes has associated with our `blue` service:
  ```bash
  kubectl describe service blue
  ```

]

In the output, there will be a line starting with `Endpoints:`.

That line will list a bunch of addresses in `host:port` format.

---

class: extra-details

## Viewing endpoint details

- When we have many endpoints, our display commands truncate the list
  ```bash
  kubectl get endpoints
  ```

- If we want to see the full list, we can use one of the following commands:
  ```bash
  kubectl describe endpoints blue
  kubectl get endpoints blue -o yaml
  ```

- These commands will show us a list of IP addresses

- These IP addresses should match the addresses of the corresponding pods:
  ```bash
  kubectl get pods -l app=blue -o wide
  ```

---

class: extra-details

## `endpoints` not `endpoint`

- `endpoints` is the only resource that cannot be singular

```bash
$ kubectl get endpoint
error: the server doesn't have a resource type "endpoint"
```

- This is because the type itself is plural (unlike every other resource)

- There is no `endpoint` object: `type Endpoints struct`

- The type doesn't represent a single endpoint, but a list of endpoints

---

class: extra-details

## The DNS zone

- In the `kube-system` namespace, there should be a service named `kube-dns`

- This is the internal DNS server that can resolve service names

- The default domain name for the service we created is `default.svc.cluster.local`

.lab[

- Get the IP address of the internal DNS server:
  ```bash
  IP=$(kubectl -n kube-system get svc kube-dns -o jsonpath={.spec.clusterIP})
  ```

- Resolve the cluster IP for the `blue` service:
  ```bash
  host blue.default.svc.cluster.local $IP
  ```

]

---

class: extra-details

## `Ingress`

- Ingresses are another type (kind) of resource

- They are specifically for HTTP services

  (not TCP or UDP)

- They can also handle TLS certificates, URL rewriting ...

- They require an *Ingress Controller* to function

---

class: pic
![](images/kubernetes-services/61-ING.png)

---

class: pic
![](images/kubernetes-services/62-ING-path.png)

---

class: pic
![](images/kubernetes-services/63-ING-policy.png)

---

class: pic
![](images/kubernetes-services/64-ING-nolocal.png)

???

:EN:- Service discovery and load balancing
:EN:- Accessing pods through services
:EN:- Service types: ClusterIP, NodePort, LoadBalancer

:FR:- Exposer un service
:FR:- Différents types de services : ClusterIP, NodePort, LoadBalancer
:FR:- Utiliser CoreDNS pour la *service discovery*
