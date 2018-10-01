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

- If we deploy a cluster with `kubeadm`, we have three namespaces:

  - `default` (for our applications)

  - `kube-system` (for the control plane)

  - `kube-public` (contains one secret used for cluster discovery)

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

- We can also use *contexts*

- A context is a *(user, cluster, namespace)* tuple

- We can manipulate contexts with the `kubectl config` command

---

## Creating a context

- We are going to create a context for the `blue` namespace

.exercise[

- View existing contexts to see the cluster name and the current user:
  ```bash
  kubectl config get-contexts
  ```

- Create a new context:
  ```bash
  kubectl config set-context blue --namespace=blue \
      --cluster=kubernetes --user=kubernetes-admin
  ```

]

We have created a context; but this is just some configuration values.

The namespace doesn't exist yet.

---

## Using a context

- Let's switch to our new context and deploy the DockerCoins chart

.exercise[

- Use the `blue` context:
  ```bash
  kubectl config use-context blue
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

Note: it might take a minute or two for the app to be up and running.

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

- View the names of the contexts:
  ```bash
  kubectl config get-contexts
  ```

- Switch back to the original context:
  ```bash
  kubectl config use-context kubernetes-admin@kubernetes
  ```

]

---

## Switching namespaces more easily

- Defining a new context for each namespace can be cumbersome

- We can also alter the current context with this one-liner:

  ```bash
  kubectl config set-context --current --namespace=foo
  ```

- We can also use a little helper tool called `kubens`:

  ```bash
  # Switch to namespace foo
  kubens foo
  # Switch back to the previous namespace
  kubens -
  ```

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
