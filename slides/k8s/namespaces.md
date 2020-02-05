# Namespaces

- We would like to deploy another copy of DockerCoins on our cluster

- We could rename all our deployments and services:

  hasher → hasher2, redis → redis2, rng → rng2, etc.

- That would require updating the code

- There has to be a better way!

--

- As hinted by the title of this section, we will use *namespaces*

---

## Identifying a resource

- We cannot have two resources with the same name

  (or can we...?)

--

- We cannot have two resources *of the same kind* with the same name

  (but it's OK to have an `rng` service, an `rng` deployment, and an `rng` daemon set)

--

- We cannot have two resources of the same kind with the same name *in the same namespace*

  (but it's OK to have e.g. two `rng` services in different namespaces)

--

- Except for resources that exist at the *cluster scope*

  (these do not belong to a namespace)

---

## Uniquely identifying a resource

- For *namespaced* resources:

  the tuple *(kind, name, namespace)* needs to be unique

- For resources at the *cluster scope*:

  the tuple *(kind, name)* needs to be unique

.exercise[

- List resource types again, and check the NAMESPACED column:
  ```bash
  kubectl api-resources
  ```

]

---

## Pre-existing namespaces

- If we deploy a cluster with `kubeadm`, we have three or four namespaces:

  - `default` (for our applications)

  - `kube-system` (for the control plane)

  - `kube-public` (contains one ConfigMap for cluster discovery)

  - `kube-node-lease` (in Kubernetes 1.14 and later; contains Lease objects)

- If we deploy differently, we may have different namespaces

---

## Creating namespaces

- Let's see two identical methods to create a namespace

.exercise[

- We can use `kubectl create namespace`:
  ```bash
  kubectl create namespace blue
  ```

- Or we can construct a very minimal YAML snippet:
  ```bash
	kubectl apply -f- <<EOF
	apiVersion: v1
	kind: Namespace
	metadata:
	  name: blue
	EOF
  ```

]

---

## Using namespaces

- We can pass a `-n` or `--namespace` flag to most `kubectl` commands:
  ```bash
  kubectl -n blue get svc
  ```

- We can also change our current *context*

- A context is a *(user, cluster, namespace)* tuple

- We can manipulate contexts with the `kubectl config` command

---

## Viewing existing contexts

- On our training environments, at this point, there should be only one context

.exercise[

- View existing contexts to see the cluster name and the current user:
  ```bash
  kubectl config get-contexts
  ```

]

- The current context (the only one!) is tagged with a `*`

- What are NAME, CLUSTER, AUTHINFO, and NAMESPACE?

---

## What's in a context

- NAME is an arbitrary string to identify the context

- CLUSTER is a reference to a cluster

  (i.e. API endpoint URL, and optional certificate)

- AUTHINFO is a reference to the authentication information to use

  (i.e. a TLS client certificate, token, or otherwise)

- NAMESPACE is the namespace

  (empty string = `default`)

---

## Switching contexts

- We want to use a different namespace

- Solution 1: update the current context

  *This is appropriate if we need to change just one thing (e.g. namespace or authentication).*

- Solution 2: create a new context and switch to it

  *This is appropriate if we need to change multiple things and switch back and forth.*

- Let's go with solution 1!

---

## Updating a context

- This is done through `kubectl config set-context`

- We can update a context by passing its name, or the current context with `--current`

.exercise[

- Update the current context to use the `blue` namespace:
  ```bash
  kubectl config set-context --current --namespace=blue
  ```

- Check the result:
  ```bash
  kubectl config get-contexts
  ```

]

---

## Using our new namespace

- Let's check that we are in our new namespace, then deploy a new copy of Dockercoins

.exercise[

- Verify that the new context is empty:
  ```bash
  kubectl get all
  ```

]

---

## Deploying DockerCoins with YAML files

- The GitHub repository `jpetazzo/kubercoins` contains everything we need!

.exercise[

- Clone the kubercoins repository:
  ```bash
  cd ~
  git clone https://github.com/jpetazzo/kubercoins
  ```

- Create all the DockerCoins resources:
  ```bash
  kubectl create -f kubercoins
  ```

]

If the argument behind `-f` is a directory, all the files in that directory are processed. 

The subdirectories are *not* processed, unless we also add the `-R` flag.

---

## Viewing the deployed app

- Let's see if this worked correctly!

.exercise[

- Retrieve the port number allocated to the `webui` service:
  ```bash
  kubectl get svc webui
  ```

- Point our browser to http://X.X.X.X:3xxxx

]

If the graph shows up but stays at zero, give it a minute or two!

---

## Namespaces and isolation

- Namespaces *do not* provide isolation

- A pod in the `green` namespace can communicate with a pod in the `blue` namespace

- A pod in the `default` namespace can communicate with a pod in the `kube-system` namespace

- CoreDNS uses a different subdomain for each namespace

- Example: from any pod in the cluster, you can connect to the Kubernetes API with:

  `https://kubernetes.default.svc.cluster.local:443/`

---

## Isolating pods

- Actual isolation is implemented with *network policies*

- Network policies are resources (like deployments, services, namespaces...)

- Network policies specify which flows are allowed:

  - between pods

  - from pods to the outside world

  - and vice-versa

---

## Switch back to the default namespace

- Let's make sure that we don't run future exercises in the `blue` namespace

.exercise[

- Switch back to the original context:
  ```bash
  kubectl config set-context --current --namespace=
  ```

]

Note: we could have used `--namespace=default` for the same result.

---

## Switching namespaces more easily

- We can also use a little helper tool called `kubens`:

  ```bash
  # Switch to namespace foo
  kubens foo
  # Switch back to the previous namespace
  kubens -
  ```

- On our clusters, `kubens` is called `kns` instead

  (so that it's even fewer keystrokes to switch namespaces)

---

##  `kubens` and `kubectx`

- With `kubens`, we can switch quickly between namespaces

- With `kubectx`, we can switch quickly between contexts

- Both tools are simple shell scripts available from https://github.com/ahmetb/kubectx

- On our clusters, they are installed as `kns` and `kctx`

  (for brevity and to avoid completion clashes between `kubectx` and `kubectl`)

---

## `kube-ps1`

- It's easy to lose track of our current cluster / context / namespace

- `kube-ps1` makes it easy to track these, by showing them in our shell prompt

- It is installed on our training clusters, and when using [shpod](https://github.com/jpetazzo/shpod)

- It gives us a prompt looking like this one:
  ```
  [123.45.67.89] `(kubernetes-admin@kubernetes:default)` docker@node1 ~
  ```
  (The highlighted part is `context:namespace`, managed by `kube-ps1`)

- Highly recommended if you work across multiple contexts or namespaces!

---

## Installing `kube-ps1`

- It's a simple shell script available from https://github.com/jonmosco/kube-ps1

- It needs to be [installed in our profile/rc files](https://github.com/jonmosco/kube-ps1#installing)

  (instructions differ depending on platform, shell, etc.)

- Once installed, it defines aliases called `kube_ps1`, `kubeon`, `kubeoff`

  (to selectively enable/disable it when needed)

- Pro-tip: install it on your machine during the next break!

