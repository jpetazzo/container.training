# K01 - Setting up a cluster with k0s

- Running a Kubernetes cluster in the cloud can be relatively straightforward

- If our cloud provider offers a managed Kubernetes service, it can be as easy as...:

  - clicking a few buttons in their web console

  - a short one-liner leveraging their CLI

  - applying a [Terraform / OpenTofu configuration][one-kubernetes]

- What if our cloud provider does not offer a managed Kubernetes service?

- What if we want to run Kubernetes on premises?

[one-kubernetes]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs/terraform/one-kubernetes

---

## A typical managed Kubernetes cluster

For instance, with Scaleway's Kapsule, we can easily get a cluster with:

- a CNI configuration providing pod network connectivity and network policies

  (Cilium by default; Calico and Kilo are also supported)

- a Cloud Controller Manager

  (to automatically label nodes; and to implement `Services` of type `LoadBalancer`)

- a CSI plugin and `StorageClass` leveraging their network-attached block storage API

- `metrics-server` to check resource utilization and horizontal pod autoscaling

- optionally, the cluster autoscaler to dynamically add/remove nodes

- optionally, a management web interface with the Kubernetes dashboard

---

## A typical cluster installed with `kubeadm`

When using a tool like `kubeadm`, we get:

- a basic control plane running on a single node

- some basic services like CoreDNS and kube-proxy

- no CNI configuration

  (our cluster won't work without one; we need to pick one and set it up ourselves)

- no Cloud Controller Manager

- no CSI plugin, no `StorageClass`

- no `metrics-server`, no cluster autoscaler, no dashboard

---

class: extra-details

## On premises Kubernetes distributions

As of October 2025, the [CNCF landscape](https://landscape.cncf.io/?fullscreen=yes&zoom=200&group=certified-partners-and-providers) lists:

- more than 60 [distributions](https://landscape.cncf.io/guide#platform--certified-kubernetes-distribution),

- at least 18 [installers](https://landscape.cncf.io/guide#platform--certified-kubernetes-installer),

- more than 20 [container runtimes](https://landscape.cncf.io/guide#runtime--container-runtime),

- more than 25 Cloud Native [network](https://landscape.cncf.io/guide#runtime--cloud-native-network) solutions,

- more than 70 Cloud Native [storage](https://landscape.cncf.io/guide#runtime--cloud-native-storage) solutions.

Which one(s) are we going to choose? And Why?

---

## Lightweight distributions

- Some Kubernetes distributions put an emphasis on being "lightweight":

  - removing non-essential features or making them optional

  - reducing or removing dependencies on external programs and libraries

  - optionally replacing etcd with another data store (e.g. built-in sqlite)

  - sometimes bundling together multiple components in a single binary for simplicity

- It often promises easier maintenance (e.g. upgrades)

- This makes them ideal for "edge" and development environments

- And sometimes they also fit the bill for regular production clusters!

---

## Introducing k0s

- Open source Kubernetes lightweight distribution

- Developed and maintained by Mirantis

  - long-time software vendor in the Kubernetes ecosystem

  - bought Docker Enterprise in 2019

- Addresses multiple segments:

  - edge computing

  - development

  - enterprise-grade HA environments

- Fully supported by Mirantis (used in [MKE4], [k0rdent], [k0smotron]...)

[MKE4]: https://www.mirantis.com/blog/mirantis-kubernetes-engine-4-released/
[k0rdent]: https://k0rdent.io/
[k0smotron]: https://k0smotron.io/

---

## `k0s` package

Its single binary includes:

- the `kubectl` CLI

- `kubelet` and a container engine (`containerd`)

- Kubernetes core control plane components

  (API server, scheduler, controller manager, etcd)

- Network components

  (like `konnectivity` and core CNI plugins)

- install, uninstall, back up, restore features

- helpers to fetch images needed for airgap environments (CoreDNS, kube-proxy...)

---

class: extra-details

## Konnectivity

- Kubernetes cluster architecture is very versatile

  (the control plane can run inside or outside of the cluster, in pods or not...)

- The control plane needs to [communicate with kubelets][api-server-to-kubelet]

  (e.g. to retrieve logs, attach to containers, forward ports...)

- The control plane also needs to [communicate with pods][api-server-to-nodes-pods-services]

  (e.g. when running admission or conversion webhooks, or aggregated APIs, in Pods)

- In some scenarios, there is no easy way for the control plane to reach nodes and pods

- The traditional approach has been to use SSH tunnels

- The modern approach is to use Konnectivity

[api-server-to-kubelet]: https://kubernetes.io/docs/concepts/architecture/control-plane-node-communication/#api-server-to-kubelet
[api-server-to-nodes-pods-services]: https://kubernetes.io/docs/concepts/architecture/control-plane-node-communication/#api-server-to-nodes-pods-and-services

---

class: extra-details

## Konnectivity architecture

- A konnectivity *server* (or *proxy*) runs on the control plane

- A konnectivity *agent* runs on each worker node (typically through a DaemonSet)

- Each agent maintains an RPC tunnel to the server

- When the control plane needs to connect to a pod or node, it solicits the proxy

---

class: pic

![konnectivity architecture](images/konnectivity.png)

---

## `k0sctl`

- It is possible to use "raw" `k0s`

  (that works great for e.g. single-node clusters)

- There is also a tool called `k0sctl`

  (wrapping `k0s` and facilitating multi-nodes installations)

.lab[

- Download the `k0sctl` binary

  ```bash
  curl -fsSL https://github.com/k0sproject/k0sctl/releases/download/v0.25.1/k0sctl-linux-amd64 \
    > /usr/local/bin/k0sctl
  chmod +x /usr/local/bin/k0sctl
  ```

]

---

## `k0sctl` configuration file

.lab[

- Create a default configuration file:
  ```bash
  k0sctl init  \
          --controller-count 3 \
          --user docker        \
          --k0s m621 m622 m623 > k0sctl.yaml
  ```

- Edit the following field so that controller nodes also run kubelet:

  `spec.hosts[*].role: controller+worker`

- Add the following fields so that controller nodes can run normal workloads:

  `spec.hosts[*].noTaints: true`

]

---

## Deploy the cluster

- `k0sctl` will connect to all our nodes using SSH

- It will copy `k0s` to the nodes

- ...And invoke it with the correct parameters

- ✨️ Magic! ✨️

.lab[

- Let's do this!
  ```bash
  k0sctl apply --config k0sctl.yaml
  ```

]

---

## Check the results

- `k0s` has multiple troubleshooting commands to check cluster health

.lab[

- Check cluster status:
  ```bash
  sudo k0s status
  ```

]

- The result should look like this:
  ```
  Version: v1.33.1+k0s.1
  Process ID: 60183
  Role: controller
  Workloads: true
  SingleNode: false
  Kube-api probing successful: true
  Kube-api probing last error:  
  ```

---

## Checking etcd status

- We can also check the status of our etcd cluster

.lab[

- Check that the etcd cluster has 3 members:
  ```bash
  sudo k0s etcd member-list
  ```
]

- The result should look like this:
  ```
  {"members":{"m621":"https://10.10.3.190:2380","m622":"https://10.10.2.92:2380",
  "m623":"https://10.10.2.110:2380"}}
  ```

---

## Running `kubectl `commands

- `k0s` embeds `kubectl` as well

.lab[

- Check that our nodes are all `Ready`:
  ```bash
  sudo k0s kubectl get nodes
  ```

]

- The result should look like this:
  ```
  NAME   STATUS   ROLES           AGE   VERSION
  m621   Ready    control-plane   66m   v1.33.1+k0s
  m622   Ready    control-plane   66m   v1.33.1+k0s
  m623   Ready    control-plane   66m   v1.33.1+k0s
  ```

---

class: extra-details

## Single node install (FYI!)

Just in case you need to quickly get a single-node cluster with `k0s`...

Download `k0s`:
```bash
curl -sSLf https://get.k0s.sh | sudo sh
```

Set up the control plane and other components:
```bash
sudo k0s install controller --single
```

Start it:
```bash
sudo k0s start
```

---

class: extra-details

## Single node uninstall

To stop the running cluster:
```bash
sudo k0s start
```

Reset and wipe its state:
```bash
sudo k0s reset
```

]

---

## Deploying shpod

- Our machines might be very barebones

- Let's get ourselves an environment with completion, colors, Helm, etc.

.lab[

- Run shpod:
  ```bash
  curl https://shpod.in | sh
  ```

]
