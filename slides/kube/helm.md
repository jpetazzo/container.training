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

- We need to install the `helm` CLI; then use it to deploy `tiller`

.exercise[

- Install the `helm` CLI:
  ```bash
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  ```

- Deploy `tiller`:
  ```bash
  helm init
  ```

- Add the `helm` completion:
  ```bash
  . <(helm completion $(basename $SHELL))
  ```

]

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

## Creating a chart

- We are going to show a way to create a *very simplified* chart

- In a real chart, *lots of things* would be templatized

  (Resource names, service types, number of replicas...)

.exercise[

- Create a sample chart:
  ```bash
  helm create dockercoins
  ```

- Move away the sample templates and create an empty template directory:
  ```bash
  mv dockercoins/templates dockercoins/default-templates
  mkdir dockercoins/templates
  ```

]

---

## Exporting the YAML for our application

- The following section assumes that DockerCoins is currently running

.exercise[

- Create one YAML file for each resource that we need:
  .small[
  ```bash

	while read kind name; do
	  kubectl get -o yaml --export $kind $name > dockercoins/templates/$name-$kind.yaml
	done <<EOF
	deployment worker
	deployment hasher
	daemonset rng
	deployment webui
	deployment redis
	service hasher
	service rng
	service webui
	service redis
	EOF
  ```
  ]

]

---

## Testing our helm chart

.exercise[

- Let's install our helm chart! (`dockercoins` is the path to the chart)
  ```bash
  helm install dockercoins
  ```
]

--

- Since the application is already deployed, this will fail:<br>
`Error: release loitering-otter failed: services "hasher" already exists`

- To avoid naming conflicts, we will deploy the application in another *namespace*
