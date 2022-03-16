# First contact with `kubectl`

- `kubectl` is (almost) the only tool we'll need to talk to Kubernetes

- It is a rich CLI tool around the Kubernetes API

  (Everything you can do with `kubectl`, you can do directly with the API)

- On our machines, there is a `~/.kube/config` file with:

  - the Kubernetes API address

  - the path to our TLS certificates used to authenticate

- You can also use the `--kubeconfig` flag to pass a config file

- Or directly `--server`, `--user`, etc.

- `kubectl` can be pronounced "Cube C T L", "Cube cuttle", "Cube cuddle"...

---

class: extra-details

## `kubectl` is the new SSH

- We often start managing servers with SSH

  (installing packages, troubleshooting ...)

- At scale, it becomes tedious, repetitive, error-prone

- Instead, we use config management, central logging, etc.

- In many cases, we still need SSH:

  - as the underlying access method (e.g. Ansible)

  - to debug tricky scenarios

  - to inspect and poke at things

---

class: extra-details

## The parallel with `kubectl`

- We often start managing Kubernetes clusters with `kubectl`

  (deploying applications, troubleshooting ...)

- At scale (with many applications or clusters), it becomes tedious, repetitive, error-prone

- Instead, we use automated pipelines, observability tooling, etc.

- In many cases, we still need `kubectl`:

  - to debug tricky scenarios

  - to inspect and poke at things

- The Kubernetes API is always the underlying access method

---

## `kubectl get`

- Let's look at our `Node` resources with `kubectl get`!

.lab[

- Look at the composition of our cluster:
  ```bash
  kubectl get node
  ```

- These commands are equivalent:
  ```bash
  kubectl get no
  kubectl get node
  kubectl get nodes
  ```

]

---

## Obtaining machine-readable output

- `kubectl get` can output JSON, YAML, or be directly formatted

.lab[

- Give us more info about the nodes:
  ```bash
  kubectl get nodes -o wide
  ```

- Let's have some YAML:
  ```bash
  kubectl get no -o yaml
  ```
  See that `kind: List` at the end? It's the type of our result!

]

---

## (Ab)using `kubectl` and `jq`

- It's super easy to build custom reports

.lab[

- Show the capacity of all our nodes as a stream of JSON objects:
  ```bash
    kubectl get nodes -o json |
            jq ".items[] | {name:.metadata.name} + .status.capacity"
  ```

]

---

class: extra-details

## Exploring types and definitions

- We can list all available resource types by running `kubectl api-resources`
  <br/>
  (In Kubernetes 1.10 and prior, this command used to be `kubectl get`)

- We can view the definition for a resource type with:
  ```bash
  kubectl explain type
  ```

- We can view the definition of a field in a resource, for instance:
  ```bash
  kubectl explain node.spec
  ```

- Or get the full definition of all fields and sub-fields:
  ```bash
  kubectl explain node --recursive
  ```

---

class: extra-details

## Introspection vs. documentation

- We can access the same information by reading the [API documentation](https://kubernetes.io/docs/reference/#api-reference)

- The API documentation is usually easier to read, but:

  - it won't show custom types (like Custom Resource Definitions)

  - we need to make sure that we look at the correct version

- `kubectl api-resources` and `kubectl explain` perform *introspection*

  (they communicate with the API server and obtain the exact type definitions)

---

## Type names

- The most common resource names have three forms:

  - singular (e.g. `node`, `service`, `deployment`)

  - plural (e.g. `nodes`, `services`, `deployments`)

  - short (e.g. `no`, `svc`, `deploy`)

- Some resources do not have a short name

- `Endpoints` only have a plural form

  (because even a single `Endpoints` resource is actually a list of endpoints)

---

## Viewing details

- We can use `kubectl get -o yaml` to see all available details

- However, YAML output is often simultaneously too much and not enough

- For instance, `kubectl get node node1 -o yaml` is:

  - too much information (e.g.: list of images available on this node)

  - not enough information (e.g.: doesn't show pods running on this node)

  - difficult to read for a human operator

- For a comprehensive overview, we can use `kubectl describe` instead

---

## `kubectl describe`

- `kubectl describe` needs a resource type and (optionally) a resource name

- It is possible to provide a resource name *prefix*

  (all matching objects will be displayed)

- `kubectl describe` will retrieve some extra information about the resource

.lab[

- Look at the information available for `node1` with one of the following commands:
  ```bash
  kubectl describe node/node1
  kubectl describe node node1
  ```

]

(We should notice a bunch of control plane pods.)

---

## Listing running containers

- Containers are manipulated through *pods*

- A pod is a group of containers:

 - running together (on the same node)

 - sharing resources (RAM, CPU; but also network, volumes)

.lab[

- List pods on our cluster:
  ```bash
  kubectl get pods
  ```

]

--

*Where are the pods that we saw just a moment earlier?!?*

---

## Namespaces

- Namespaces allow us to segregate resources

.lab[

- List the namespaces on our cluster with one of these commands:
  ```bash
  kubectl get namespaces
  kubectl get namespace
  kubectl get ns
  ```

]

--

*You know what ... This `kube-system` thing looks suspicious.*

*In fact, I'm pretty sure it showed up earlier, when we did:*

`kubectl describe node node1`

---

## Accessing namespaces

- By default, `kubectl` uses the `default` namespace

- We can see resources in all namespaces with `--all-namespaces`

.lab[

- List the pods in all namespaces:
  ```bash
  kubectl get pods --all-namespaces
  ```

- Since Kubernetes 1.14, we can also use `-A` as a shorter version:
  ```bash
  kubectl get pods -A
  ```

]

*Here are our system pods!*

---

## What are all these control plane pods?

- `etcd` is our etcd server

- `kube-apiserver` is the API server

- `kube-controller-manager` and `kube-scheduler` are other control plane components

- `coredns` provides DNS-based service discovery ([replacing kube-dns as of 1.11](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/))

- `kube-proxy` is the (per-node) component managing port mappings and such

- `weave` is the (per-node) component managing the network overlay

- the `READY` column indicates the number of containers in each pod

  (1 for most pods, but `weave` has 2, for instance)

---

## Scoping another namespace

- We can also look at a different namespace (other than `default`)

.lab[

- List only the pods in the `kube-system` namespace:
  ```bash
  kubectl get pods --namespace=kube-system
  kubectl get pods -n kube-system
  ```

]

---

## Namespaces and other `kubectl` commands

- We can use `-n`/`--namespace` with almost every `kubectl` command

- Example:

  - `kubectl create --namespace=X` to create something in namespace X

- We can use `-A`/`--all-namespaces` with most commands that manipulate multiple objects

- Examples:

  - `kubectl delete` can delete resources across multiple namespaces

  - `kubectl label` can add/remove/update labels across multiple namespaces

---

class: extra-details

## What about `kube-public`?

.lab[

- List the pods in the `kube-public` namespace:
  ```bash
  kubectl -n kube-public get pods
  ```

]

Nothing!

`kube-public` is created by kubeadm & [used for security bootstrapping](https://kubernetes.io/blog/2017/01/stronger-foundation-for-creating-and-managing-kubernetes-clusters).

---

class: extra-details

## Exploring `kube-public`

- The only interesting object in `kube-public` is a ConfigMap named `cluster-info`

.lab[

- List ConfigMap objects:
  ```bash
  kubectl -n kube-public get configmaps
  ```

- Inspect `cluster-info`:
  ```bash
  kubectl -n kube-public get configmap cluster-info -o yaml
  ```

]

Note the `selfLink` URI: `/api/v1/namespaces/kube-public/configmaps/cluster-info`

We can use that!

---

class: extra-details

## Accessing `cluster-info`

- Earlier, when trying to access the API server, we got a `Forbidden` message

- But `cluster-info` is readable by everyone (even without authentication)

.lab[

- Retrieve `cluster-info`:
  ```bash
  curl -k https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info
  ```

]

- We were able to access `cluster-info` (without auth)

- It contains a `kubeconfig` file

---

class: extra-details

## Retrieving `kubeconfig`

- We can easily extract the `kubeconfig` file from this ConfigMap

.lab[

- Display the content of `kubeconfig`:
  ```bash
    curl -sk https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info \
         | jq -r .data.kubeconfig
  ```

]

- This file holds the canonical address of the API server, and the public key of the CA

- This file *does not* hold client keys or tokens

- This is not sensitive information, but allows us to establish trust

---

class: extra-details

## What about `kube-node-lease`?

- Starting with Kubernetes 1.14, there is a `kube-node-lease` namespace

  (or in Kubernetes 1.13 if the NodeLease feature gate is enabled)

- That namespace contains one Lease object per node

- *Node leases* are a new way to implement node heartbeats

  (i.e. node regularly pinging the control plane to say "I'm alive!")

- For more details, see [Efficient Node Heartbeats KEP] or the [node controller documentation]

[Efficient Node Heartbeats KEP]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/589-efficient-node-heartbeats/README.md
[node controller documentation]: https://kubernetes.io/docs/concepts/architecture/nodes/#node-controller

---

## Services

- A *service* is a stable endpoint to connect to "something"

  (In the initial proposal, they were called "portals")

.lab[

- List the services on our cluster with one of these commands:
  ```bash
  kubectl get services
  kubectl get svc
  ```

]

--

There is already one service on our cluster: the Kubernetes API itself.

---

## ClusterIP services

- A `ClusterIP` service is internal, available from the cluster only

- This is useful for introspection from within containers

.lab[

- Try to connect to the API:
  ```bash
  curl -k https://`10.96.0.1`
  ```

  - `-k` is used to skip certificate verification

  - Make sure to replace 10.96.0.1 with the CLUSTER-IP shown by `kubectl get svc`

]

The command above should either time out, or show an authentication error. Why?

---

## Time out

- Connections to ClusterIP services only work *from within the cluster*

- If we are outside the cluster, the `curl` command will probably time out

  (Because the IP address, e.g. 10.96.0.1, isn't routed properly outside the cluster)

- This is the case with most "real" Kubernetes clusters

- To try the connection from within the cluster, we can use [shpod](https://github.com/jpetazzo/shpod)

---

## Authentication error

This is what we should see when connecting from within the cluster:
```json
$ curl -k https://10.96.0.1
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {

  },
  "code": 403
}
```

---

## Explanations

- We can see `kind`, `apiVersion`, `metadata`

- These are typical of a Kubernetes API reply

- Because we *are* talking to the Kubernetes API

- The Kubernetes API tells us "Forbidden"

  (because it requires authentication)

- The Kubernetes API is reachable from within the cluster

  (many apps integrating with Kubernetes will use this)

---

## DNS integration

- Each service also gets a DNS record

- The Kubernetes DNS resolver is available *from within pods*

  (and sometimes, from within nodes, depending on configuration)

- Code running in pods can connect to services using their name

  (e.g. https://kubernetes/...)

???

:EN:- Getting started with kubectl
:FR:- Se familiariser avec kubectl
