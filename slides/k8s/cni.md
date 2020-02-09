# The Container Network Interface

- Allows us to decouple network configuration from Kubernetes

- Implemented by *plugins*

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

## How does kubelet know which plugins to use?

- The plugin (or list of plugins) is set in the CNI configuration

- The CNI configuration is a *single file* in `/etc/cni/net.d`

- If there are multiple files in that directory, the first one is used

  (in lexicographic order)

- That path can be changed with the `--cni-conf-dir` flag of kubelet

---

## CNI configuration in practice

- When we set up the "pod network" (like Calico, Weave...) it ships a CNI configuration

  (and sometimes, custom CNI plugins)

- Very often, that configuration (and plugins) is installed automatically

  (by a DaemonSet featuring an initContainer with hostPath volumes)

- Examples:

  - Calico [CNI config](https://github.com/projectcalico/calico/blob/1372b56e3bfebe2b9c9cbf8105d6a14764f44159/v2.6/getting-started/kubernetes/installation/hosted/calico.yaml#L25)
    and [volume](https://github.com/projectcalico/calico/blob/1372b56e3bfebe2b9c9cbf8105d6a14764f44159/v2.6/getting-started/kubernetes/installation/hosted/calico.yaml#L219)

  - kube-router [CNI config](https://github.com/cloudnativelabs/kube-router/blob/c2f893f64fd60cf6d2b6d3fee7191266c0fc0fe5/daemonset/generic-kuberouter.yaml#L10)
    and [volume](https://github.com/cloudnativelabs/kube-router/blob/c2f893f64fd60cf6d2b6d3fee7191266c0fc0fe5/daemonset/generic-kuberouter.yaml#L73)

---

class: extra-details

## Conf vs conflist

- There are two slightly different configuration formats

- Basic configuration format:

  - holds configuration for a single plugin
  - typically has a `.conf` name suffix
  - has a `type` string field in the top-most structure
  - [examples](https://github.com/containernetworking/cni/blob/master/SPEC.md#example-configurations)

- Configuration list format:

  - can hold configuration for multiple (chained) plugins
  - typically has a `.conflist` name suffix
  - has a `plugins` list field in the top-most structure
  - [examples](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists)

---

class: extra-details

## How plugins are invoked

- Parameters are given through environment variables, including:

  - CNI_COMMAND: desired operation (ADD, DEL, CHECK, or VERSION)

  - CNI_CONTAINERID: container ID

  - CNI_NETNS: path to network namespace file

  - CNI_IFNAME: what the network interface should be named

- The network configuration must be provided to the plugin on stdin

  (this avoids race conditions that could happen by passing a file path)

---

## In practice: kube-router

- We are going to set up a new cluster

- For this new cluster, we will use kube-router

- kube-router will provide the "pod network"

  (connectivity with pods)

- kube-router will also provide internal service connectivity

  (replacing kube-proxy)

---

## How kube-router works

- Very simple architecture

- Does not introduce new CNI plugins

  (uses the `bridge` plugin, with `host-local` for IPAM)

- Pod traffic is routed between nodes

  (no tunnel, no new protocol)

- Internal service connectivity is implemented with IPVS

- Can provide pod network and/or internal service connectivity

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

---

class: extra-details

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

## The plan

- We'll work in a new cluster (named `kuberouter`)

- We will run a simple control plane (like before)

- ... But this time, the controller manager will allocate `podCIDR` subnets

  (so that we don't have to manually assign subnets to individual nodes)

- We will create a DaemonSet for kube-router

- We will join nodes to the cluster

- The DaemonSet will automatically start a kube-router pod on each node

---

## Logging into the new cluster

.exercise[

- Log into node `kuberouter1`

- Clone the workshop repository:
  ```bash
  git clone https://@@GITREPO@@
  ```

- Move to this directory:
  ```bash
  cd container.training/compose/kube-router-k8s-control-plane
  ```

]

---

class: extra-details

## Checking the CNI configuration

- By default, kubelet gets the CNI configuration from `/etc/cni/net.d`

.exercise[

- Check the content of `/etc/cni/net.d`

]

(On most machines, at this point, `/etc/cni/net.d` doesn't even exist).)

---

## Our control plane

- We will use a Compose file to start the control plane

- It is similar to the one we used with the `kubenet` cluster

- The API server is started with `--allow-privileged`

  (because we will start kube-router in privileged pods)

- The controller manager is started with extra flags too:

  `--allocate-node-cidrs` and `--cluster-cidr`

- We need to edit the Compose file to set the Cluster CIDR

---

## Starting the control plane

- Our cluster CIDR will be `10.C.0.0/16`

  (where `C` is our cluster number)

.exercise[

- Edit the Compose file to set the Cluster CIDR:
  ```bash
  vim docker-compose.yaml
  ```

- Start the control plane:
  ```bash
  docker-compose up
  ```

]

---

## The kube-router DaemonSet

- In the same directory, there is a `kuberouter.yaml` file

- It contains the definition for a DaemonSet and a ConfigMap

- Before we load it, we also need to edit it

- We need to indicate the address of the API server

  (because kube-router needs to connect to it to retrieve node information)

---

## Creating the DaemonSet

- The address of the API server will be `http://A.B.C.D:8080`

  (where `A.B.C.D` is the public address of `kuberouter1`, running the control plane)

.exercise[

- Edit the YAML file to set the API server address:
  ```bash
  vim kuberouter.yaml
  ```

- Create the DaemonSet:
  ```bash
  kubectl create -f kuberouter.yaml
  ```

]

Note: the DaemonSet won't create any pods (yet) since there are no nodes (yet).

---

## Generating the kubeconfig for kubelet

- This is similar to what we did for the `kubenet` cluster

.exercise[

- Generate the kubeconfig file (replacing `X.X.X.X` with the address of `kuberouter1`):
  ```bash
    kubectl config set-cluster cni --server http://`X.X.X.X`:8080
    kubectl config set-context cni --cluster cni
    kubectl config use-context cni
    cp ~/.kube/config ~/kubeconfig
  ```

]

---

## Distributing kubeconfig

- We need to copy that kubeconfig file to the other nodes

.exercise[

- Copy `kubeconfig` to the other nodes:
  ```bash
    for N in 2 3; do
    	scp ~/kubeconfig kuberouter$N:
    done
  ```

]

---

## Starting kubelet

- We don't need the `--pod-cidr` option anymore

  (the controller manager will allocate these automatically)

- We need to pass `--network-plugin=cni`

.exercise[

- Join the first node:
   ```bash
   sudo kubelet --kubeconfig ~/kubeconfig --network-plugin=cni
   ```

- Open more terminals and join the other nodes:
  ```bash
  ssh kuberouter2 sudo kubelet --kubeconfig ~/kubeconfig --network-plugin=cni
  ssh kuberouter3 sudo kubelet --kubeconfig ~/kubeconfig --network-plugin=cni
  ```

]

---

class: extra-details

## Checking the CNI configuration

- At this point, kuberouter should have installed its CNI configuration

  (in `/etc/cni/net.d`)

.exercise[

- Check the content of `/etc/cni/net.d`

]

- There should be a file created by kuberouter

- The file should contain the node's podCIDR

---

## Setting up a test

- Let's create a Deployment and expose it with a Service

.exercise[

- Create a Deployment running a web server:
  ```bash
  kubectl create deployment web --image=jpetazzo/httpenv
  ```

- Scale it so that it spans multiple nodes:
  ```bash
  kubectl scale deployment web --replicas=5
  ```

- Expose it with a Service:
  ```bash
  kubectl expose deployment web --port=8888
  ```

]

---

## Checking that everything works

.exercise[

- Get the ClusterIP address for the service:
  ```bash
  kubectl get svc web
  ```

- Send a few requests there:
  ```bash
  curl `X.X.X.X`:8888
  ```

]

Note that if you send multiple requests, they are load-balanced in a round robin manner.

This shows that we are using IPVS (vs. iptables, which picked random endpoints).

---

class: extra-details

## Troubleshooting

- What if we need to check that everything is working properly?

.exercise[

- Check the IP addresses of our pods:
  ```bash
  kubectl get pods -o wide
  ```

- Check our routing table:
  ```bash
  route -n
  ip route
  ```

]

We should see the local pod CIDR connected to `kube-bridge`, and the other nodes' pod CIDRs having individual routes, with each node being the gateway.

---

class: extra-details

## More troubleshooting

- We can also look at the output of the kube-router pods

  (with `kubectl logs`)

- kube-router also comes with a special shell that gives lots of useful info

  (we can access it with `kubectl exec`)

- But with the current setup of the cluster, these options may not work!

- Why?

---

class: extra-details

## Trying `kubectl logs` / `kubectl exec`

.exercise[

- Try to show the logs of a kube-router pod:
  ```bash
  kubectl -n kube-system logs ds/kube-router
  ```

- Or try to exec into one of the kube-router pods:
  ```bash
  kubectl -n kube-system exec kube-router-xxxxx bash
  ```

]

These commands will give an error message that includes:
```
dial tcp: lookup kuberouterX on 127.0.0.11:53: no such host
```

What does that mean?

---

class: extra-details

## Internal name resolution

- To execute these commands, the API server needs to connect to kubelet

- By default, it creates a connection using the kubelet's name

  (e.g. `http://kuberouter1:...`)

- This requires our nodes names to be in DNS

- We can change that by setting a flag on the API server:

  `--kubelet-preferred-address-types=InternalIP`

---

class: extra-details

## Another way to check the logs

- We can also ask the logs directly to the container engine

- First, get the container ID, with `docker ps` or like this:
  ```bash
  CID=$(docker ps -q \
        --filter label=io.kubernetes.pod.namespace=kube-system \
        --filter label=io.kubernetes.container.name=kube-router)
  ```

- Then view the logs:
  ```bash
  docker logs $CID
  ```

---

class: extra-details

## Other ways to distribute routing tables

- We don't need kube-router and BGP to distribute routes

- The list of nodes (and associated `podCIDR` subnets) is available through the API

- This shell snippet generates the commands to add all required routes on a node:

```bash
NODES=$(kubectl get nodes -o name | cut -d/ -f2)
for DESTNODE in $NODES; do
  if [ "$DESTNODE" != "$HOSTNAME" ]; then
    echo $(kubectl get node $DESTNODE -o go-template="
      route add -net {{.spec.podCIDR}} gw {{(index .status.addresses 0).address}}")
  fi
done
```

- This could be useful for embedded platforms with very limited resources

  (or lab environments for learning purposes)
