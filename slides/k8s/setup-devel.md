# Running a local development cluster

- Let's review some options to run Kubernetes locally

- There is no "best option", it depends what you value:

  - ability to run on all platforms (Linux, Mac, Windows, other?)

  - ability to run clusters with multiple nodes

  - ability to run multiple clusters side by side

  - ability to run recent (or even, unreleased) versions of Kubernetes

  - availability of plugins

  - etc.

---

### CoLiMa

- Container runtimes for LiMa

  (LiMa = Linux on macOS)

- For macOS only (Intel and ARM architectures)

- CLI-driven (no GUI like Docker/Rancher Desktop)

- Supports containerd, Docker, Kubernetes

- Installable with brew, nix, or ports

- More info: https://github.com/abiosoft/colima

---

## Docker Desktop

- Available on Linux, Mac, and Windows

- Free for personal use and small businesses

  (less than 250 employees and less than $10 millions in annual revenue)

- Gives you one cluster with one node

- Streamlined installation and user experience

- Great integration with various network stacks and e.g. corporate VPNs

- Ideal for Docker users who need good integration between both platforms

---

## [k3d](https://k3d.io/)

- Based on [K3s](https://k3s.io/) by Rancher Labs

- Requires Docker

- Runs Kubernetes nodes in Docker containers

- Can deploy multiple clusters, with multiple nodes

- Runs the control plane on Kubernetes nodes

- Control plane can also run on multiple nodes

---

## k3d in action

- Install `k3d` (e.g. get the binary from https://github.com/rancher/k3d/releases)

- Create a simple cluster:
  ```bash
  k3d cluster create petitcluster
  ```

- Create a more complex cluster with a custom version:
  ```bash
  k3d cluster create groscluster \
        --image rancher/k3s:v1.18.9-k3s1 --servers 3 --agents 5
  ```

  (3 nodes for the control plane + 5 worker nodes)
 
- Clusters are automatically added to `.kube/config` file

---

## [KinD](https://kind.sigs.k8s.io/)

- Kubernetes-in-Docker

- Requires Docker (obviously!)

- Should also work with Podman and Rootless Docker

- Deploying a single node cluster using the latest version is simple:
  ```bash
  kind create cluster
  ```

- More advanced scenarios require writing a short [config file](https://kind.sigs.k8s.io/docs/user/quick-start#configuring-your-kind-cluster)

  (to define multiple nodes, multiple control plane nodes, set Kubernetes versions ...)
 
- Can deploy multiple clusters

---

## [MicroK8s](https://microk8s.io/)

- Available on Linux, and since recently, on Mac and Windows as well

- The Linux version is installed through Snap

  (which is pre-installed on all recent versions of Ubuntu)

- Also supports clustering (as in, multiple machines running MicroK8s)

- DNS is not enabled by default; enable it with `microk8s enable dns`

---

## [Minikube](https://minikube.sigs.k8s.io/docs/)

- The "legacy" option!

  (note: this is not a bad thing, it means that it's very stable, has lots of plugins, etc.)

- Supports many [drivers](https://minikube.sigs.k8s.io/docs/drivers/)

  (HyperKit, Hyper-V, KVM, VirtualBox, but also Docker and many others)

- Can deploy a single cluster; recent versions can deploy multiple nodes

- Great option if you want a "Kubernetes first" experience

  (i.e. if you don't already have Docker and/or don't want/need it)

---

## [Rancher Desktop](https://rancherdesktop.io/)

- Available on Linux, Mac, and Windows

- Free and open-source

- Runs a single cluster with a single node

- Lets you pick the Kubernetes version that you want to use

  (and change it any time you like)

- Emphasis on ease of use (like Docker Desktop)

- Relatively young product (first release in May 2021)

- Based on k3s and other proven components

---

## VM with custom install

- Choose your own adventure!

- Pick any Linux distribution!

- Build your cluster from scratch or use a Kubernetes installer!

- Discover exotic CNI plugins and container runtimes!

- The only limit is yourself, and the time you are willing to sink in!

???

:EN:- Kubernetes options for local development
:FR:- Installation de Kubernetes pour travailler en local
