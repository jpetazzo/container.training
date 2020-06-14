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

## Docker Desktop

- Available on Mac and Windows

- Gives you one cluster with one node

- Rather old version of Kubernetes

- Very easy to use if you are already using Docker Desktop:

  go to Docker Desktop preferences and enable Kubernetes

- Ideal for Docker users who need good integration between both platforms

---

## [k3d](https://k3d.io/)

- Based on [K3s](https://k3s.io/) by Rancher Labs

- Requires Docker

- Runs Kubernetes nodes in Docker containers

- Can deploy multiple clusters, with multiple nodes, and multiple master nodes

- As of June 2020, two versions co-exist: stable (1.7) and beta (3.0)

- They have different syntax and options, this can be confusing

  (but don't let that stop you!)

---

## k3d in action

- Get `k3d` beta 3 binary on https://github.com/rancher/k3d/releases

- Create a simple cluster:
  ```bash
  k3d create cluster petitcluster --update-kubeconfig
  ```

- Use it:
  ```bash
  kubectl config use-context k3d-petitcluster
  ```

- Create a more complex cluster with a custom version:
  ```bash
  k3d create cluster groscluster --update-kubeconfig \
        --image rancher/k3s:v1.18.3-k3s1 --masters 3 --workers 5 --api-port 6444
  ```

  (note: API port seems to be necessary when running multiple clusters)

---

## [KinD](https://kind.sigs.k8s.io/)

- Kubernetes-in-Docker

- Requires Docker (obviously!)

- Deploying a single node cluster using the latest version is simple:
  ```bash
  kind create cluster
  ```

- More advanced scenarios require writing a short [config file](https://kind.sigs.k8s.io/docs/user/quick-start#configuring-your-kind-cluster)

  (to define multiple nodes, multiple master nodes, set Kubernetes versions ...)
 
- Can deploy multiple clusters

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

## [MicroK8s](https://microk8s.io/)

- Available on Linux, and since recently, on Mac and Windows as well

- The Linux version is installed through Snap

  (which is pre-installed on all recent versions of Ubuntu)

- Also supports clustering (as in, multiple machines running MicroK8s)

- DNS is not enabled by default; enable it with `microk8s enable dns`

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
