# Managing stacks with Helm

- We created our first resources with `kubectl run`, `kubectl expose` ...

- We have also created resources by loading YAML files with `kubectl apply -f`

- For larger stacks, managing thousands of lines of YAML is unreasonable

- These YAML bundles need to be customized with variable parameters

  (E.g.: number of replicas, image version to use ...)

- It would be nice to have an organized, versioned collection of bundles

- It would be nice to be able to upgrade/rollback these bundles carefully

- [Helm](https://helm.sh/) is an open source project offering all these things!

---

## Helm concepts

- `helm` is a CLI tool

- `tiller` is its companion server-side component

- A "chart" is an archive containing templatized YAML bundles

- Charts are versioned

- Charts can be stored on private or public repositories

---

## Installing Helm

- If the `helm` CLI is not installed in your environment, install it

.exercise[

- Check if `helm` is installed:
  ```bash
  helm
  ```

- If it's not installed, run the following command:
  ```bash
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  ```

]

---

## Installing Tiller

- Tiller is composed of a *service* and a *deployment* in the `kube-system` namespace

- They can be managed (installed, upgraded...) with the `helm` CLI

.exercise[

- Deploy Tiller:
  ```bash
  helm init
  ```

]

If Tiller was already installed, don't worry: this won't break it.

At the end of the install process, you will see:

```
Happy Helming!
```

---

## Fix account permissions

- Helm permission model requires us to tweak permissions

- In a more realistic deployment, you might create per-user or per-team
  service accounts, roles, and role bindings

.exercise[

- Grant `cluster-admin` role to `kube-system:default` service account:
  ```bash
  kubectl create clusterrolebinding add-on-cluster-admin \
      --clusterrole=cluster-admin --serviceaccount=kube-system:default
  ```

]

(Defining the exact roles and permissions on your cluster requires
a deeper knowledge of Kubernetes' RBAC model. The command above is
fine for personal and development clusters.)

---

## View available charts

- A public repo is pre-configured when installing Helm

- We can view available charts with `helm search` (and an optional keyword)

.exercise[

- View all available charts:
  ```bash
  helm search
  ```

- View charts related to `prometheus`:
  ```bash
  helm search prometheus
  ```

]

---

## Install a chart

- Most charts use `LoadBalancer` service types by default

- Most charts require persistent volumes to store data

- We need to relax these requirements a bit

.exercise[

- Install the Prometheus metrics collector on our cluster:
  ```bash
  helm install stable/prometheus \
         --set server.service.type=NodePort \
         --set server.persistentVolume.enabled=false
  ```

]

Where do these `--set` options come from?

---

## Inspecting a chart

- `helm inspect` shows details about a chart (including available options)

.exercise[

- See the metadata and all available options for `stable/prometheus`:
  ```bash
  helm inspect stable/prometheus
  ```

]

The chart's metadata includes an URL to the project's home page.

(Sometimes it conveniently points to the documentation for the chart.)

---

## Viewing installed charts

- Helm keeps track of what we've installed

.exercise[

- List installed Helm charts:
  ```bash
  helm list
  ```

]
