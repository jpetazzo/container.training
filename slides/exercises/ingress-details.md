# Exercise — Ingress

- We want to expose a couple of web apps through an ingress controller

- This will require:

  - the web apps (e.g. two instances of `jpetazzo/color`)

  - an ingress controller

  - an ingress resource

---

## Different scenarios

We will use a different deployment mechanism depending on the cluster that we have:

- Managed cluster with working `LoadBalancer` Services

- Local development cluster

- Cluster without `LoadBalancer` Services (e.g. deployed with `kubeadm`)

---

## The apps

- The web apps will be deployed similarly, regardless of the scenario

- Let's start by deploying two web apps, e.g.:

  a Deployment called `blue` and another called `green`, using image `jpetazzo/color`

- Expose them with two `ClusterIP` Services

---

## Scenario "classic cloud Kubernetes"

*Difficulty: easy*

For this scenario, we need a cluster with working `LoadBalancer` Services.

(For instance, a managed Kubernetes cluster from a cloud provider.)

We suggest to use "Ingress NGINX" with its default settings.

It can be installed with `kubectl apply` or with `helm`.

Both methods are described in [the documentation][ingress-nginx-deploy].

We want our apps to be available on e.g. http://X.X.X.X/blue and http://X.X.X.X/green
<br/>
(where X.X.X.X is the IP address of the `LoadBalancer` allocated by Ingress NGINX).

[ingress-nginx-deploy]: https://kubernetes.github.io/ingress-nginx/deploy/

---

## Scenario "local development cluster"

*Difficulty: easy-hard (depends on the type of cluster!)*

For this scenario, we want to use a local cluster like KinD, minikube, etc.

We suggest to use "Ingress NGINX" again, like for the previous scenario.

Furthermore, we want to use `localdev.me`.

We want our apps to be available on e.g. `blue.localdev.me` and `green.localdev.me`.

The difficulty is to ensure that `localhost:80` will map to the ingress controller.

(See next slide for hints!)

---

## Hints

- With clusters like Docker Desktop, the first `LoadBalancer` service uses `localhost`

  (if the ingress controller is the first `LoadBalancer` service, we're all set!)

- With clusters like K3D and KinD, it is possible to define extra port mappings

  (and map e.g. `localhost:80` to port 30080 on the node; then use that as a `NodePort`)

---

## Scenario "on premises cluster", take 1

*Difficulty: easy*

For this scenario, we need a cluster with nodes that are publicly accessible.

We want to deploy the ingress controller so that it listens on port 80 on all nodes.

This can be done e.g. with the manifests in @@LINK[k8s/traefik.yaml].

We want our apps to be available on e.g. http://X.X.X.X/blue and http://X.X.X.X/green
<br/>
(where X.X.X.X is the IP address of any of our nodes).

---

## Scenario "on premises cluster", take 2

*Difficulty: medium*

We want to deploy the ingress controller so that it listens on port 80 on all nodes.

But this time, we want to use a Helm chart to install the ingress controller.

We can use either the Ingress NGINX Helm chart, or the Traefik Helm chart.

Test with an untainted node first.

Feel free to make it work on tainted nodes (e.g. control plane nodes) later.

---

## Scenario "on premises cluster", take 3

*Difficulty: hard*

This is similar to the previous scenario, but with two significant changes:

1. We only want to run the ingress controller on nodes that have the role `ingress`.

2. We don't want to use `hostNetwork`, but a list of `externalIPs` instead.
