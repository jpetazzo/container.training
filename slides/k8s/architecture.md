# Kubernetes architecture

We can arbitrarily split Kubernetes in two parts:

- the *nodes*, a set of machines that run our containerized workloads;

- the *control plane*, a set of processes implementing the Kubernetes APIs.

Kubernetes also relies on underlying infrastructure:

- servers, network connectivity (obviously!),

- optional components like storage systems, load balancers ...

---

class: pic

![Kubernetes architecture diagram: communication between components](images/k8s-arch4-thanks-luxas.png)

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

## Control plane location

The control plane can run:

- in containers, on the same nodes that run other application workloads

  (default behavior for local clusters like [Minikube](https://github.com/kubernetes/minikube), [kind](https://kind.sigs.k8s.io/)...)

- on a dedicated node

  (default behavior when deploying with kubeadm)

- on a dedicated set of nodes

  ([Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way); [kops](https://github.com/kubernetes/kops); also kubeadm)

- outside of the cluster

  (most managed clusters like AKS, DOK, EKS, GKE, Kapsule, LKE, OKE...)

---

class: pic

![](images/control-planes/single-node-dev.svg)

---

class: pic

![](images/control-planes/managed-kubernetes.svg)

---

class: pic

![](images/control-planes/single-control-and-workers.svg)

---

class: pic

![](images/control-planes/stacked-control-plane.svg)

---

class: pic

![](images/control-planes/advanced-control-plane.svg)

---

class: pic

![](images/control-planes/advanced-control-plane-split-events.svg)

---

class: pic

![](images/control-planes/non-dedicated-stacked-nodes.svg)

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

- For this section, we can use any cluster

.lab[

- Check that the cluster is operational:
  ```bash
  kubectl get nodes
  ```

- All nodes should be `Ready`

]

---

## Create

- Let's create a simple object

.lab[

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

.lab[

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

class: extra-details

## Group-Version-Kind, or GVK

- A particular type will be identified by the combination of:

  - the API group it belongs to (core, `apps`, `metrics.k8s.io`, ...)

  - the version of this API group (`v1`, `v1beta1`, ...)

  - the "Kind" itself (Pod, Role, Job, ...)

- "GVK" appears a lot in the API machinery code

- Conversions are possible between different versions and even between API groups

  (e.g. when Deployments moved from `extensions` to `apps`)

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

.lab[

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

class: extra-details

## Watch events

- `kubectl get --watch` shows changes

- If we add `--output-watch-events`, we can also see:

  - the difference between ADDED and MODIFIED resources

  - DELETED resources

.lab[

- In one terminal, watch pods, displaying full events:
  ```bash
  kubectl get pods --watch --output-watch-events
  ```

- In another, run a short-lived pod:
  ```bash
  kubectl run pause --image=alpine --rm -ti --restart=Never -- sleep 5
  ```

]

---

## Other control plane components

- API server ✔️

- etcd ✔️

- Controller manager

- Scheduler

---

## Controller manager

- This is a collection of loops watching all kinds of objects

- That's where the actual logic of Kubernetes lives

- When we create a Deployment (e.g. with `kubectl create deployment web --image=nginx`),

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

---

class: extra-details

## How many nodes should a cluster have?

- There is no particular constraint

  (no need to have an odd number of nodes for quorum)

- A cluster can have zero node

  (but then it won't be able to start any pods)

- For testing and development, having a single node is fine

- For production, make sure that you have extra capacity

  (so that your workload still fits if you lose a node or a group of nodes)

- Kubernetes is tested with [up to 5000 nodes](https://kubernetes.io/docs/setup/best-practices/cluster-large/)

  (however, running a cluster of that size requires a lot of tuning)

---

class: extra-details

## Do we need to run Docker at all?

No!

--

- The Docker Engine used to be the default option to run containers with Kubernetes

- Support for Docker (specifically: dockershim) was removed in Kubernetes 1.24

- We can leverage other pluggable runtimes through the *Container Runtime Interface*

- <del>We could also use `rkt` ("Rocket") from CoreOS</del> (deprecated)

---

class: extra-details

## Some runtimes available through CRI

- [containerd](https://github.com/containerd/containerd/blob/master/README.md)

  - maintained by Docker, IBM, and community
  - used by Docker Engine, microk8s, k3s, GKE; also standalone
  - comes with its own CLI, `ctr`

- [CRI-O](https://github.com/cri-o/cri-o/blob/master/README.md):

  - maintained by Red Hat, SUSE, and community
  - used by OpenShift and Kubic
  - designed specifically as a minimal runtime for Kubernetes

- [And more](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

---

class: extra-details

## Do we need to run Docker at all?

Yes!

--

- In this workshop, we run our app on a single node first

- We will need to build images and ship them around

- We can do these things without Docker
  <br/>
  (but with some languages/frameworks, it might be much harder)

- Docker is still the most stable container engine today
  <br/>
  (but other options are maturing very quickly)

---

class: extra-details

## Do we need to run Docker at all?

- On our Kubernetes clusters:

  *Not anymore*

- On our development environments, CI pipelines ... :

  *Yes, almost certainly*

---

## Interacting with Kubernetes

- We will interact with our Kubernetes cluster through the Kubernetes API

- The Kubernetes API is (mostly) RESTful

- It allows us to create, read, update, delete *resources*

- A few common resource types are:

  - node (a machine — physical or virtual — in our cluster)

  - pod (group of containers running together on a node)

  - service (stable network endpoint to connect to one or multiple containers)

---

class: pic

![Node, pod, container](images/k8s-arch3-thanks-weave.png)

---

## Scaling

- How would we scale the pod shown on the previous slide?

- **Do** create additional pods

  - each pod can be on a different node

  - each pod will have its own IP address

- **Do not** add more NGINX containers in the pod

  - all the NGINX containers would be on the same node

  - they would all have the same IP address
    <br/>(resulting in `Address alreading in use` errors)

---

## Together or separate

- Should we put e.g. a web application server and a cache together?
  <br/>
  ("cache" being something like e.g. Memcached or Redis)

- Putting them **in the same pod** means:

  - they have to be scaled together

  - they can communicate very efficiently over `localhost`

- Putting them **in different pods** means:

  - they can be scaled separately

  - they must communicate over remote IP addresses
    <br/>(incurring more latency, lower performance)

- Both scenarios can make sense, depending on our goals

???

:EN:- Kubernetes architecture review
:FR:- Passage en revue de l'architecture de Kubernetes
