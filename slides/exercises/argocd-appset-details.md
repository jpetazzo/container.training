# Exercise — ArgoCD AppSet

We want to leverage ArgoCD to deploy the DockerCoins app with a generic Helm chart.

We also want to avoid repeating or copy-pasting YAML manifests for each component.

We will do this with an ArgoCD Application Set.

---

## Step 1

- Deploy the DockerCoins app with the following constraints:

  - use a generic helm chart (e.g. [this one][kubercoins-generic-service])

  - create a single ArgoCD Application Set instead of multiple Applications

---

## Step 2

- Add the following features:

  - deploy multiple instances in different namespaces

  - each instance can have different Helm values

---

## Step 3

Same as step 2, but with a single Application Set.

(For instance, using directory-based discovery, with one directory per environment.)

[kubercoins-generic-service]: https://github.com/jpetazzo/kubercoins/tree/helm/generic-service
