# Kubernetes network model

- TL,DR:

  *Our cluster (nodes and pods) is one big flat IP network.*

--

- In detail:

 - all nodes can reach each other directly (without NAT)

 - all pods can reach each other directly (without NAT)

 - pods and nodes can reach each other directly (without NAT)

 - each pod is aware of its IP address (again: no NAT)

- Most Kubernetes clusters rely on the CNI to configure Pod networking

  (allocate IP addresses, create and configure network interfaces, routing...)

---

## Kubernetes network model: the good

- Everything can reach everything

- No address translation

- No port translation

- No new protocol

- IP addresses are allocated by the network stack, not by the users

  (this avoids complex constraints associated with address portability)

- CNI is very flexible and lends itself to many different models

  (switching, routing, tunneling... virtually anything is possible!)

- Example: we could have one subnet per node and use a simple routed topology

---

## Kubernetes network model: the less good

- Everything can reach everything

  - if we want network isolation, we need to add network policies

  - some clusters (like AWS EKS) don't include a network policy controller out of the box

- There are literally dozens of Kubernetes network implementations out there

  (https://github.com/containernetworking/cni/ lists more than 25 plugins)

- Pods have level 3 (IP) connectivity, but *services* are level 4 (TCP or UDP)

  (Services map to a single UDP or TCP port; no port ranges or arbitrary IP packets)

- The default Kubernetes service proxy, `kube-proxy`, doesn't scale very well

  (although this is improved considerably in [recent versions of kube-proxy][tables-have-turned])

[tables-have-turned]: https://www.youtube.com/watch?v=yOGHb2HjslY

---

## Kubernetes network model: in practice

- We don't need to worry about networking in local development clusters

  (it's set up automatically for us and we almost never need to change anything)

- We also don't need to worry about it in managed clusters

  (except if we want to reconfigure or replace whatever was installed automatically)

- We *do* need to pick a network stack in all other scenarios:

  - installing Kubernetes on bare metal or on "raw" virtual machines

  - when we manage the control plane ourselves

---

## Which network stack should we use?

*It depends!*

- [Weave] = super easy to install, no config needed, low footprint...
  
  *but it's not maintained anymore, alas!*

- [Cilium] = very powerful and flexible, some consider it "best in class"...

  *but it's based on eBPF, which might make troubleshooting challenging!*

- Other solid choices include [Calico], [Flannel], [kube-router]

- And of course, some cloud providers / network vendors have their own solutions

  (which may or may not be appropriate for your use-case!)

- Do you want speed? Reliability? Security? Observability?

[Weave]: https://github.com/weaveworks/weave
[Cilium]: https://cilium.io/
[Calico]: https://docs.tigera.io/calico/latest/about/
[Flannel]: https://github.com/flannel-io/flannel
[kube-router]: https://www.kube-router.io/

---

## Multiple moving parts

- The "pod-to-pod network" or "pod network" or "CNI":

  - provides communication between pods and nodes

  - is generally implemented with CNI plugins

- The "pod-to-service network" or "Kubernetes service proxy":

  - provides internal communication and load balancing

  - implemented with kube-proxy by default

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
