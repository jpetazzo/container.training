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

- We can create namespaces with a very minimal YAML, e.g.:
  ```bash
	kubectl apply -f- <<EOF
	apiVersion: v1
	kind: Namespace
	metadata:
	  name: blue
	EOF
  ```

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

- `kube-dns` uses a different subdomain for each namespace

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

## Network policies overview

- We can create as many network policies as we want

- Each network policy has:

  - a *pod selector*: "which pods are targeted by the policy?"

  - lists of ingress and/or egress rules: "which peers and ports are allowed or blocked?"

- If a pod is not targeted by any policy, traffic is allowed by default

- If a pod is targeted by at least one policy, traffic must be allowed explicitly

---

## More about network policies

- This remains a high level overview of network policies

- For more details, check:

  - the [Kubernetes documentation about network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

  - this [talk about network policies at KubeCon 2017 US](https://www.youtube.com/watch?v=3gGpMmYeEO8) by [@ahmetb](https://twitter.com/ahmetb)
