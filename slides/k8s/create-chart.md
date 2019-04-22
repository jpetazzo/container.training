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
  ```
  helm install dockercoins
  ```
]

--

- Since the application is already deployed, this will fail:<br>
`Error: release loitering-otter failed: services "hasher" already exists`

- To avoid naming conflicts, we will deploy the application in another *namespace*
