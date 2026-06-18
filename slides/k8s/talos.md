# Setting up a cluster with Talos

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

- more than 65 [distributions](https://landscape.cncf.io/guide#platform--certified-kubernetes-distribution),

- at least 18 [installers](https://landscape.cncf.io/guide#platform--certified-kubernetes-installer),

- more than 26 [container runtimes](https://landscape.cncf.io/guide#runtime--container-runtime),

- more than 27 Cloud Native [network](https://landscape.cncf.io/guide#runtime--cloud-native-network) solutions,

- more than 80 Cloud Native [storage](https://landscape.cncf.io/guide#runtime--cloud-native-storage) solutions.

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

## Introducing Talos

- Open source Kubernetes-dedicated Linux lightweight distribution

- Developed and maintained by Sidero Labs

- Hugely refactored Linux

  - less than 50 binaries (smallest attack surface)

  - no shell, no ssh, a single endpoint `apid` on port 50000

  - / is a read-only FS

---

## Booting Talos

- Most of the configuration is done during building the Talos image in [Talos Software Factory]

    - type of server that will run the OS (VM, Cloud Instance, PXE-installed bare-metal server)

    - specfic kernel modules, drivers, and configuration

- Once it has boot, you can access it with the [talosctl] CLI

- Kubernetes

  - control plane components are static pods

  - control plane nodes are tainted

[Talos Software Factory]: https://factory.talos.dev
[talosctl]: https://docs.siderolabs.com/talos/v1.13/learn-more/talosctl

---

## Cilium configuration file

To use Cilium as a CNI, we need to create a `cilium-patch.yaml` file.

.lab[

```YAML
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true
```

]

---

## Generating Talos configuration file

.lab[

```bash
export CLUSTER_NAME="my-talos"
export API_SERVER="talos1"

talosctl gen config "$CLUSTER_NAME" "https://${API_SERVER}:6443" \
  --output ./talos-out \
  --additional-sans "$API_SERVER" \
  --additional-sans "$firstNodeIP" \
  --config-patch @cilium-patch.yaml
```

]

---

## Prepare Talos configuration

.lab[

- You may configure your nodes IP once for all

```bash
export firstNodeIP=…
export secondNodeIP=…
export thirdNodeIP=…
```

-  Define the Talos endpoints IP(s)

```bash
talosctl --talosconfig ./talos-out/talosconfig
  config endpoint $firstNodeIP $secondNodeIP $thirdNodeIP
```

- Define Kubernetes nodes IP(s)

```bash
talosctl --talosconfig ./talos-out/talosconfig config node $firstNodeIP $secondNodeIP $thirdNodeIP
```

]

---

## Check the current configuration

.lab[

```bash
talosctl --talosconfig ./talos-out/talosconfig config info
```

]

---

## Apply configuration for control plane

.lab[

- Apply control plane configuration to the 1st node

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  apply-config --insecure \
  --file ./talos-out/controlplane.yaml
```

]

- Do the same for the other nodes BUT WAIT for 10 secs between nodes

---

## Bootstrap the control plane

.lab[

- Bootstrap etcd for the 1st node of the control plane

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  bootstrap
```

- Check the cluster health

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  health
```

- Check the etcd cluster status

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  --endpoints $firstNodeIP \
  get members
```

]

---

## Connect with kubectl

.lab[

- Get kubeconfig from the cluster

```bash
mkdir -p ~/.kube
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  --endpoints $firstNodeIP \
  kubeconfig ~/.kube/config
```

- Check access to the cluster

```bash
kubectl cluster-info
kubectl get nodes
```

]

---

## Add worker capabilities to Control Plane nodes

.lab[

- Untaint Control Plane so that they can be worker nodes as well

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  edit machineconfig
```

- Comment the machine.nodeTaints section

]

---

## Install Cilium as a CNI

.lab[

- Add Cilium Helm repository
```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
```

- Install Cilium
```bash
helm install cilium cilium/cilium --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=$firstNodeIP \
  --set k8sServicePort=6443
```

]

---

## Watch kubelet logs

.lab[

```bash
talosctl --talosconfig ./talos-out/talosconfig --nodes $firstNodeIP \
  logs kubelet | tail -n 20
```

]
