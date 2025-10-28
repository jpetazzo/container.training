# Service Types

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

---

class: extra-details

## Traffic engineering

- By default, connections to a ClusterIP or a NodePort are load balanced
  across all the backends of their Service

- This can incur extra network hops (which add latency)

- To remove that extra hop, multiple mechanisms are available:

  - `spec.externalTrafficPolicy`

  - `spec.internalTrafficPolicy`

  - [Topology aware routing](https://kubernetes.io/docs/concepts/services-networking/topology-aware-routing/) annotation (beta)

  - `spec.trafficDistribution` (alpha in 1.30, beta in 1.31)

---

## `internal / externalTrafficPolicy`

- Applies respectively to `ClusterIP` and `NodePort` connections

- Can be set to `Cluster` or `Local`

- `Cluster`: load balance connections across all backends (default)

- `Local`: load balance connections to local backends (on the same node)

- With `Local`, if there is no local backend, the connection will fail!

  (the parameter expresses a "hard rule", not a preference)

- Example: `externalTrafficPolicy: Local` for Ingress controllers

  (as shown on earlier diagrams)

---

class: extra-details

## Topology aware routing

- In beta since Kubernetes 1.23

- Enabled with annotation `service.kubernetes.io/topology-mode=Auto` 

- Relies on node label `topology.kubernetes.io/zone`

- Kubernetes service proxy will try to keep connections within a zone

  (connections made by a pod in zone `a` will be sent to pods in zone `a`)

- ...Except if there are no pods in the zone (then fallback to all zones)

- This can mess up autoscaling!

---

class: extra-details

## `spec.trafficDistribution`

- [KEP4444, Traffic Distribution for Services][kep4444]

- Supersedes topology aware routing

- Multiple values are supported

- `PreferClose` (alpha since K8S 1.30, beta since K8S 1.31, stable since K8S 1.33)

  "try to route traffic to endpoints in the same zone as the client"

- `PreferSameZone` (beta since K8S 1.34)

  "same as `PreferClose` but clearer about the intended semantics"

- `PreferSameNode` (beta since K8S 1.34)

  "try to route traffic to endpoints on the same node as the client"

[kep4444]: https://github.com/kubernetes/enhancements/issues/4444

???

:EN:- Service types: ClusterIP, NodePort, LoadBalancer

:FR:- Différents types de services : ClusterIP, NodePort, LoadBalancer
