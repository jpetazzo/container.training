class: title

Beyond kubenet

---

## When kubenet is not enough (1/2)

- IP address allocation is rigid

  (one subnet per node)

- What about DHCP?

- What about e.g. ENI on AWS?

  (allocating Elastic Network Interfaces to containers)

---

## When kubenet is not enough (1/2)

- Containers are connected to a Linux bridge

- What about:

  - Open vSwitch

  - VXLAN

  - skipping layer 2

  - using directly a network interface (macvlan, SR-IOV...)

---

## The Container Network Interface

- Allows us to decouple network configuration from Kubernetes

- Implemented by plugins

- Plugins are executables that will be invoked by kubelet

- Plugins are responsible for:

  - allocating IP addresses for containers

  - configuring the network for containers

- Plugins can be combined and chained when it makes sense

---

## Combining plugins

- Interface could be created by e.g. `vlan` or `bridge` plugin

- IP address could be allocated by e.g. `dhcp` or `host-local` plugin

- Interface parameters (MTU, sysctls) could be tweaked by the `tuning` plugin

The reference plugins are available [here].

Look in each plugin's directory for its documentation.

[here]: https://github.com/containernetworking/plugins/tree/master/plugins

---

## How plugins are invoked

- Parameters are given through environment variables, including:

  - CNI_COMMAND: desired operation (ADD, DEL, CHECK, or VERSION)

  - CNI_CONTAINERID: container ID

  - CNI_NETNS: path to network namespace file

  - CNI_IFNAME: what the network interface should be named

- The network configuration must be provided to the plugin on stdin

  (this avoids race conditions that could happen by passing a file path)

---

## Setting up CNI

- We are going to use kube-router

- kube-router will provide the "pod network"

  (connectivity with pods)

- kube-router will also provide internal service connectivity

  (replacing kube-proxy)

- kube-router can also function as a Network Policy Controller

  (implementing firewalling between pods)

---

## How kube-router works

- Very simple architecture

- Does not introduce new CNI plugins

  (uses the `bridge` plugin, with `host-local` for IPAM)

- Pod traffic is routed between nodes

  (no tunnel, no new protocol)

- Internal service connectivity is implemented with IPVS

- kube-router daemon runs on every node

---

## What kube-router does

- Connect to the API server

- Obtain the local node's `podCIDR`

- Inject it into the CNI configuration file

  (we'll use `/etc/cni/net.d/10-kuberouter.conflist`)

- Obtain the addresses of all nodes

- Establish a *full mesh* BGP peering with the other nodes

- Exchange routes over BGP

- Add routes to the Linux kernel

---

## What's BGP?

- BGP (Border Gateway Protocol) is the protocol used between internet routers

- It [scales](https://www.cidr-report.org/as2.0/)
  pretty [well](https://www.cidr-report.org/cgi-bin/plota?file=%2fvar%2fdata%2fbgp%2fas2.0%2fbgp-active%2etxt&descr=Active%20BGP%20entries%20%28FIB%29&ylabel=Active%20BGP%20entries%20%28FIB%29&with=step)
  (it is used to announce the 700k CIDR prefixes of the internet)

- It is spoken by many hardware routers from many vendors

- It also has many software implementations (Quagga, Bird, FRR...)

- Experienced network folks generally know it (and appreciate it)

- It also used by Calico (another popular network system for Kubernetes)

- Using BGP allows us to interconnect our "pod network" with other systems

---

class: pic

![Demo time!](images/demo-with-kht.png)
