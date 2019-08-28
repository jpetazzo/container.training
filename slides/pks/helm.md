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

--

*We're going to use the beta of Helm 3 as it does not require `tiller` making things simpler and more secure for us.*
---

## Installing Helm

- If the `helm` 3 CLI is not installed in your environment, [install it](https://github.com/helm/helm/releases/tag/v3.0.0-beta.1)

.exercise[

- Check if `helm` is installed:
  ```bash
  helm version
  ```
]

--

```bash
version.BuildInfo{Version:"v3.0.0-beta.1", GitCommit:"f76b5f21adb53a85de8925f4a9d4f9bd99f185b5", GitTreeState:"clean", GoVersion:"go1.12.9"}`
```

---

## Oops you accidently a Helm 2

If `helm version` gives you a result like below it means you have helm 2 which requires the `tiller` server side component.

```
Client: &version.Version{SemVer:"v2.14.0", GitCommit:"05811b84a3f93603dd6c2fcfe57944dfa7ab7fd0", GitTreeState:"clean"}
Error: forwarding ports: error upgrading connection: pods "tiller-deploy-6fd87785-x8sxk" is forbidden: User "user1" cannot create resource "pods/portforward" in API group "" in the namespace "kube-system"
```

Run `EXPORT TILLER_NAMESPACE=<username>` and try again. We've pre-installed `tiller` for you in your namespace just in case.

--

Some of the commands in the following may not work in helm 2. Good luck!

---

## Installing Tiller

*If you were running Helm 2 you would need to install Tiller. We can skip this.*

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

*If you were running Helm 2 you would need to install Tiller. We can skip this.*

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
  helm search hub
  ```

- View charts related to `prometheus`:
  ```bash
  helm search hub prometheus
  ```

]

---

## Add the stable chart repository

- Helm 3 does not come configured with any repositories, so we need to start by adding the stable repo.

.exercise[
  - Add the stable repo
  ```bash
  helm repo add stable https://kubernetes-charts.storage.googleapis.com/
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
         prometheus \
         --set server.service.type=ClusterIP \
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

The chart's metadata includes a URL to the project's home page.

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
