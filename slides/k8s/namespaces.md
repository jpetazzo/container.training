# Namespaces

- We cannot have two resources with the same name

  (Or can we...?)

--

- We cannot have two resources *of the same type* with the same name

  (But it's OK to have a `rng` service, a `rng` deployment, and a `rng` daemon set!)

--

- We cannot have two resources of the same type with the same name *in the same namespace*

  (But it's OK to have e.g. two `rng` services in different namespaces!)

--

- In other words: **the tuple *(type, name, namespace)* needs to be unique**

  (In the resource YAML, the type is called `Kind`)

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

- Creating a namespace is done with the `kubectl create namespace` command:
  ```bash
  kubectl create namespace blue
  ```

- We can also get fancy and use a very minimal YAML snippet, e.g.:
  ```bash
	kubectl apply -f- <<EOF
	apiVersion: v1
	kind: Namespace
	metadata:
	  name: blue
	EOF
  ```

- The two methods above are identical

- If we are using a tool like Helm, it will create namespaces automatically

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

- Let's check that we are in our new namespace, then deploy the DockerCoins chart

.exercise[

- Verify that the new context is empty:
  ```bash
  kubectl get all
  ```

- Deploy DockerCoins:
  ```bash
  helm install dockercoins
  ```

]

In the last command line, `dockercoins` is just the local path where
we created our Helm chart before.

---

## Viewing the deployed app

- Let's see if our Helm chart worked correctly!

.exercise[

- Retrieve the port number allocated to the `webui` service:
  ```bash
  kubectl get svc webui
  ```

- Point our browser to http://X.X.X.X:3xxxx

]

If the graph shows up but stays at zero, check the next slide!

---

## Troubleshooting

If did the exercices from the chapter about labels and selectors,
the app that you just created may not work, because the `rng` service
selector has `enabled=yes` but the pods created by the `rng` daemon set
do not have that label.

How can we troubleshoot that?

- Query individual services manually

  → the `rng` service will time out

- Inspect the services with `kubectl describe service`
  
  → the `rng` service will have an empty list of backends

---

## Fixing the broken service

The easiest option is to add the `enabled=yes` label to the relevant pods.

.exercise[

- Add the `enabled` label to the pods of the `rng` daemon set:
  ```bash
  kubectl label pods -l app=rng enabled=yes
  ```

]

The *best* option is to change either the service definition, or the
daemon set definition, so that their respective selectors match correctly.

*This is left as an exercise for the reader!*

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

- It's a simple shell script available from https://github.com/jonmosco/kube-ps1

- On our clusters, `kube-ps1` is installed and included in `PS1`:
  ```
  [123.45.67.89] `(kubernetes-admin@kubernetes:default)` docker@node1 ~
  ```
  (The highlighted part is `context:namespace`, managed by `kube-ps1`)

- Highly recommended if you work across multiple contexts or namespaces!
