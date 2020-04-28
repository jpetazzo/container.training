# Creating a basic chart

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

- If DockerCoins is not running, see next slide

.exercise[

- Create one YAML file for each resource that we need:
  .small[
  ```bash

	while read kind name; do
	  kubectl get -o yaml $kind $name > dockercoins/templates/$name-$kind.yaml
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

## Obtaining DockerCoins YAML

- If DockerCoins is not running, we can also obtain the YAML from a public repository

.exercise[

- Clone the kubercoins repository:
  ```bash
  git clone https://github.com/jpetazzo/kubercoins
  ```

- Copy the YAML files to the `templates/` directory:
  ```bash
  cp kubercoins/*.yaml dockercoins/templates/
  ```

]

---

## Testing our helm chart

.exercise[

- Let's install our helm chart!
  ```
  helm install helmcoins dockercoins
  ```
  (`helmcoins` is the name of the release; `dockercoins` is the local path of the chart)

]

--

- Since the application is already deployed, this will fail:
```
Error: rendered manifests contain a resource that already exists.
Unable to continue with install: existing resource conflict:
kind: Service, namespace: default, name: hasher
```

- To avoid naming conflicts, we will deploy the application in another *namespace*

---

## Switching to another namespace

- We need create a new namespace

  (Helm 2 creates namespaces automatically; Helm 3 doesn't anymore)

- We need to tell Helm which namespace to use

.exercise[

- Create a new namespace:
  ```bash
  kubectl create namespace helmcoins
  ```

- Deploy our chart in that namespace:
  ```bash
  helm install helmcoins dockercoins --namespace=helmcoins
  ```

]

---

## Helm releases are namespaced

- Let's try to see the release that we just deployed

.exercise[

- List Helm releases:
  ```bash
  helm list
  ```

]

Our release doesn't show up!

We have to specify its namespace (or switch to that namespace).

---

## Specifying the namespace

- Try again, with the correct namespace

.exercise[

- List Helm releases in `helmcoins`:
  ```bash
  helm list --namespace=helmcoins
  ```

]

---

## Checking our new copy of DockerCoins

- We can check the worker logs, or the web UI

.exercise[

- Retrieve the NodePort number of the web UI:
  ```bash
  kubectl get service webui --namespace=helmcoins
  ```

- Open it in a web browser

- Look at the worker logs:
  ```bash
  kubectl logs deploy/worker --tail=10 --follow --namespace=helmcoins
  ```

]

Note: it might take a minute or two for the worker to start.

---

## Discussion, shortcomings

- Helm (and Kubernetes) best practices recommend to add a number of annotations

  (e.g. `app.kubernetes.io/name`, `helm.sh/chart`, `app.kubernetes.io/instance` ...)

- Our basic chart doesn't have any of these

- Our basic chart doesn't use any template tag

- Does it make sense to use Helm in that case?

- *Yes,* because Helm will:

  - track the resources created by the chart

  - save successive revisions, allowing us to rollback

[Helm docs](https://helm.sh/docs/topics/chart_best_practices/labels/)
and [Kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
have details about recommended annotations and labels.

---

## Cleaning up

- Let's remove that chart before moving on

.exercise[

- Delete the release (don't forget to specify the namespace):
  ```bash
  helm delete helmcoins --namespace=helmcoins
  ```

]

???

:EN:- Writing a basic Helm chart for the whole app
:FR:- Écriture d'un *chart* Helm simplifié
