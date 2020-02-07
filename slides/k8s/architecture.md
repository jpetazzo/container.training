# Kubernetes architecture

We can arbitrarily split Kubernetes in two parts:

- the *nodes*, a set of machines that run our containerized workloads;

- the *control plane*, a set of processes implementing the Kubernetes APIs.

Kubernetes also relies on underlying infrastructure:

- servers, network connectivity (obviously!),

- optional components like storage systems, load balancers ...

---

## Control plane location

The control plane can run:

- in containers, on the same nodes that run other application workloads

  (example: [Minikube](https://github.com/kubernetes/minikube); 1 node runs everything, [kind](https://kind.sigs.k8s.io/))

- on a dedicated node

  (example: a cluster installed with kubeadm)

- on a dedicated set of nodes

  (example: [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way); [kops](https://github.com/kubernetes/kops))

- outside of the cluster

  (example: most managed clusters like AKS, EKS, GKE)

---

class: pic

![Kubernetes architecture diagram: control plane and nodes](images/k8s-arch2.png)

---

## What runs on a node

- Our containerized workloads

- A container engine like Docker, CRI-O, containerd...

  (in theory, the choice doesn't matter, as the engine is abstracted by Kubernetes)

- kubelet: an agent connecting the node to the cluster

  (it connects to the API server, registers the node, receives instructions)

- kube-proxy: a component used for internal cluster communication

  (note that this is *not* an overlay network or a CNI plugin!)

---

## What's in the control plane

- Everything is stored in etcd

  (it's the only stateful component)

- Everyone communicates exclusively through the API server:

  - we (users) interact with the cluster through the API server

  - the nodes register and get their instructions through the API server

  - the other control plane components also register with the API server

- API server is the only component that reads/writes from/to etcd

---

## Communication protocols: API server

- The API server exposes a REST API

  (except for some calls, e.g. to attach interactively to a container)

- Almost all requests and responses are JSON following a strict format

- For performance, the requests and responses can also be done over protobuf

  (see this [design proposal](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/api-machinery/protobuf.md) for details)

- In practice, protobuf is used for all internal communication

  (between control plane components, and with kubelet)

---

## Communication protocols: on the nodes

The kubelet agent uses a number of special-purpose protocols and interfaces, including:

- CRI (Container Runtime Interface)

  - used for communication with the container engine
  - abstracts the differences between container engines
  - based on gRPC+protobuf

- [CNI (Container Network Interface)](https://github.com/containernetworking/cni/blob/master/SPEC.md)

  - used for communication with network plugins
  - network plugins are implemented as executable programs invoked by kubelet
  - network plugins provide IPAM
  - network plugins set up network interfaces in pods

---

class: pic

![Kubernetes architecture diagram: communication between components](images/k8s-arch4-thanks-luxas.png)

---

# The Kubernetes API

[
*The Kubernetes API server is a "dumb server" which offers storage, versioning, validation, update, and watch semantics on API resources.*
](
https://github.com/kubernetes/community/blob/master/contributors/design-proposals/api-machinery/protobuf.md#proposal-and-motivation
)

([Clayton Coleman](https://twitter.com/smarterclayton), Kubernetes Architect and Maintainer)

What does that mean?

---

## The Kubernetes API is declarative

- We cannot tell the API, "run a pod"

- We can tell the API, "here is the definition for pod X"

- The API server will store that definition (in etcd)

- *Controllers* will then wake up and create a pod matching the definition

---

## The core features of the Kubernetes API

- We can create, read, update, and delete objects

- We can also *watch* objects

  (be notified when an object changes, or when an object of a given type is created)

- Objects are strongly typed

- Types are *validated* and *versioned*

- Storage and watch operations are provided by etcd

  (note: the [k3s](https://k3s.io/) project allows us to use sqlite instead of etcd)

---

## Let's experiment a bit!

- For the exercises in this section, connect to the first node of the `test` cluster

.exercise[

- SSH to the first node of the test cluster

- Check that the cluster is operational:
  ```bash
  kubectl get nodes
  ```

- All nodes should be `Ready`

]

---

## Create

- Let's create a simple object

.exercise[

- Create a namespace with the following command:
  ```bash
    kubectl create -f- <<EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      name: hello
    EOF
  ```

]

This is equivalent to `kubectl create namespace hello`.

---

## Read

- Let's retrieve the object we just created

.exercise[

- Read back our object:
  ```bash
  kubectl get namespace hello -o yaml
  ```

]

We see a lot of data that wasn't here when we created the object.

Some data was automatically added to the object (like `spec.finalizers`).

Some data is dynamic (typically, the content of `status`.)

---

## API requests and responses

- Almost every Kubernetes API payload (requests and responses) has the same format:
  ```yaml
    apiVersion: xxx
    kind: yyy
    metadata:
      name: zzz
      (more metadata fields here)
    (more fields here)
  ```

- The fields shown above are mandatory, except for some special cases

  (e.g.: in lists of resources, the list itself doesn't have a `metadata.name`)

- We show YAML for convenience, but the API uses JSON

  (with optional protobuf encoding)

---

class: extra-details

## API versions

- The `apiVersion` field corresponds to an *API group*

- It can be either `v1` (aka "core" group or "legacy group"), or `group/versions`; e.g.:

  - `apps/v1`
  - `rbac.authorization.k8s.io/v1`
  - `extensions/v1beta1`

- It does not indicate which version of Kubernetes we're talking about

- It *indirectly* indicates the version of the `kind`

  (which fields exist, their format, which ones are mandatory...)

- A single resource type (`kind`) is rarely versioned alone

  (e.g.: the `batch` API group contains `jobs` and `cronjobs`)

---

## Update

- Let's update our namespace object

- There are many ways to do that, including:

  - `kubectl apply` (and provide an updated YAML file)
  - `kubectl edit`
  - `kubectl patch`
  - many helpers, like `kubectl label`, or `kubectl set`

- In each case, `kubectl` will:

  - get the current definition of the object
  - compute changes
  - submit the changes (with `PATCH` requests)

---

## Adding a label

- For demonstration purposes, let's add a label to the namespace

- The easiest way is to use `kubectl label`

.exercise[

- In one terminal, watch namespaces:
  ```bash
  kubectl get namespaces --show-labels -w
  ```

- In the other, update our namespace:
  ```bash
  kubectl label namespaces hello color=purple
  ```

]

We demonstrated *update* and *watch* semantics.

---

## What's special about *watch*?

- The API server itself doesn't do anything: it's just a fancy object store

- All the actual logic in Kubernetes is implemented with *controllers*

- A *controller* watches a set of resources, and takes action when they change

- Examples:

  - when a Pod object is created, it gets scheduled and started

  - when a Pod belonging to a ReplicaSet terminates, it gets replaced

  - when a Deployment object is updated, it can trigger a rolling update

---

# Other control plane components

- API server ✔️

- etcd ✔️

- Controller manager

- Scheduler

---

## Controller manager

- This is a collection of loops watching all kinds of objects

- That's where the actual logic of Kubernetes lives

- When we create a Deployment (e.g. with `kubectl run web --image=nginx`),

  - we create a Deployment object

  - the Deployment controller notices it, and creates a ReplicaSet

  - the ReplicaSet controller notices the ReplicaSet, and creates a Pod

---

## Scheduler

- When a pod is created, it is in `Pending` state

- The scheduler (or rather: *a scheduler*) must bind it to a node

  - Kubernetes comes with an efficient scheduler with many features

  - if we have special requirements, we can add another scheduler
    <br/>
    (example: this [demo scheduler](https://github.com/kelseyhightower/scheduler) uses the cost of nodes, stored in node annotations)

- A pod might stay in `Pending` state for a long time:

  - if the cluster is full

  - if the pod has special constraints that can't be met

  - if the scheduler is not running (!)
