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

