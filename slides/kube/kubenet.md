# Kubernetes network model

- TL,DR:

  *Our cluster (nodes and pods) is one big flat IP network.*

--

- In detail:

 - all nodes must be able to reach each other, without NAT

 - all pods must be able to reach each other, without NAT

 - pods and nodes must be able to reach each other, without NAT

 - each pod is aware of its IP address (no NAT)

- Kubernetes doesn't mandate any particular implementation

---

## Kubernetes network model: the good

- Everything can reach everything

- No address translation

- No port translation

- No new protocol

- Pods cannot move from a node to another and keep their IP address

- IP addresses don't have to be "portable" from a node to another

  (We can use e.g. a subnet per node and use a simple routed topology)

- The specification is simple enough to allow many various implementations

---

## Kubernetes network model: the less good

- Everything can reach everything

  - if you want security, you need to add network policies

  - the network implementation that you use needs to support them

- There are literally dozens of implementations out there

  (15 are listed in the Kubernetes documentation)

- Pods have level 3 (IP) connectivity, but *services* are level 4

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

## The Container Network Interface (CNI)

- The CNI has a well-defined [specification](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration) for network plugins

- When a pod is created, Kubernetes delegates the network setup to CNI plugins

- Typically, a CNI plugin will:

  - allocate an IP address (by calling an IPAM plugin)

  - add a network interface into the pod's network namespace

  - configure the interface as well as required routes etc.

- Using multiple plugins can be done with "meta-plugins" like CNI-Genie or Multus

- Not all CNI plugins are equal

  (e.g. they don't all implement network policies, which are required to isolate pods)
