# Kubernetes network model

- TL,DR:

  *Our cluster (nodes and pods) is one big flat IP network.*

--

- In detail:

 - all nodes must be able to reach each other, without NAT

 - all pods must be able to reach each other, without NAT

 - pods and nodes must be able to reach each other, without NAT

 - each pod is aware of its IP address (no NAT)

 - pod IP addresses are assigned by the network implementation

- Kubernetes doesn't mandate any particular implementation

---

## Kubernetes network model: the good

- Everything can reach everything

- No address translation

- No port translation

- No new protocol

- The network implementation can decide how to allocate addresses

- IP addresses don't have to be "portable" from a node to another

  (We can use e.g. a subnet per node and use a simple routed topology)

- The specification is simple enough to allow many various implementations

---

## Kubernetes network model: the less good

- Everything can reach everything

  - if you want security, you need to add network policies

  - the network implementation that you use needs to support them

- There are literally dozens of implementations out there

  (https://github.com/containernetworking/cni/ lists more than 25 plugins)

- Pods have level 3 (IP) connectivity, but *services* are level 4 (TCP or UDP)

  (Services map to a single UDP or TCP port; no port ranges or arbitrary IP packets)

- `kube-proxy` is on the data path when connecting to a pod or container,
  <br/>and it's not particularly fast (relies on userland proxying or iptables)

---

## Kubernetes network model: in practice

- The nodes that we are using have been set up to use [Weave](https://github.com/weaveworks/weave)

- We don't endorse Weave in a particular way, it just Works For Us

- Don't worry about the warning about `kube-proxy` performance

- Unless you:

  - routinely saturate 10G network interfaces
  - count packet rates in millions per second
  - run high-traffic VOIP or gaming platforms
  - do weird things that involve millions of simultaneous connections
    <br/>(in which case you're already familiar with kernel tuning)

- If necessary, there are alternatives to `kube-proxy`; e.g.
  [`kube-router`](https://www.kube-router.io)

---

class: extra-details

## The Container Network Interface (CNI)

- Most Kubernetes clusters use CNI "plugins" to implement networking

- When a pod is created, Kubernetes delegates the network setup to these plugins

  (it can be a single plugin, or a combination of plugins, each doing one task)

- Typically, CNI plugins will:

  - allocate an IP address (by calling an IPAM plugin)

  - add a network interface into the pod's network namespace

  - configure the interface as well as required routes etc.

---

class: extra-details

## Multiple moving parts

- The "pod-to-pod network" or "pod network":

  - provides communication between pods and nodes

  - is generally implemented with CNI plugins

- The "pod-to-service network":

  - provides internal communication and load balancing

  - is generally implemented with kube-proxy (or e.g. kube-router)

- Network policies:

  - provide firewalling and isolation

  - can be bundled with the "pod network" or provided by another component

---

class: pic

![Overview of the three Kubernetes network layers](images/k8s-net-0-overview.svg)

---

class: pic

![Pod-to-pod network](images/k8s-net-1-pod-to-pod.svg)

---

class: pic

![Pod-to-service network](images/k8s-net-2-pod-to-svc.svg)

---

class: pic

![Network policies](images/k8s-net-3-netpol.svg)

---

class: pic

![View with all the layers again](images/k8s-net-4-overview.svg)

---

class: extra-details

## Even more moving parts

- Inbound traffic can be handled by multiple components:

  - something like kube-proxy or kube-router (for NodePort services)

  - load balancers (ideally, connected to the pod network)

- It is possible to use multiple pod networks in parallel

  (with "meta-plugins" like CNI-Genie or Multus)

- Some solutions can fill multiple roles

  (e.g. kube-router can be set up to provide the pod network and/or network policies and/or replace kube-proxy)

???

:EN:- The Kubernetes network model
:FR:- Le modèle réseau de Kubernetes
