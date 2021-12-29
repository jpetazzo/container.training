# Creating a basic chart

- We are going to show a way to create a *very simplified* chart

- In a real chart, *lots of things* would be templatized

  (Resource names, service types, number of replicas...)

.lab[

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

## Adding the manifests of our app

- There is a convenient `dockercoins.yml` in the repo

.lab[

- Copy the YAML file to the `templates` subdirectory in the chart:
  ```bash
  cp ~/container.training/k8s/dockercoins.yaml dockercoins/templates
  ```

]

- Note: it is probably easier to have multiple YAML files

  (rather than a single, big file with all the manifests)

- But that works too!

---

## Testing our Helm chart

- Our Helm chart is now ready

  (as surprising as it might seem!)

.lab[

- Let's try to install the chart:
  ```
  helm install helmcoins dockercoins
  ```
  (`helmcoins` is the name of the release; `dockercoins` is the local path of the chart)

]

--

- If the application is already deployed, this will fail:
```
Error: rendered manifests contain a resource that already exists.
Unable to continue with install: existing resource conflict:
kind: Service, namespace: default, name: hasher
```

---

## Switching to another namespace

- If there is already a copy of dockercoins in the current namespace:

  - we can switch with `kubens` or `kubectl config set-context`

  - we can also tell Helm to use a different namespace

.lab[

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

.lab[

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

.lab[

- List Helm releases in `helmcoins`:
  ```bash
  helm list --namespace=helmcoins
  ```

]

---

## Checking our new copy of DockerCoins

- We can check the worker logs, or the web UI

.lab[

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

.lab[

- Delete the release (don't forget to specify the namespace):
  ```bash
  helm delete helmcoins --namespace=helmcoins
  ```

]

---

## Tips when writing charts

- It is not necessary to `helm install`/`upgrade` to test a chart

- If we just want to look at the generated YAML, use `helm template`:
  ```bash
  helm template ./my-chart
  helm template release-name ./my-chart
  ```

- Of course, we can use `--set` and `--values` too

- Note that this won't fully validate the YAML!

  (e.g. if there is `apiVersion: klingon` it won't complain)

- This can be used when trying things out

---

## Exploring the templating system

Try to put something like this in a file in the `templates` directory:

```yaml
hello: {{ .Values.service.port }}
comment: {{/* something completely.invalid !!!  */}}
type: {{ .Values.service | typeOf | printf }}
### print complex value
{{ .Values.service | toYaml }}
### indent it
indented:
{{ .Values.service | toYaml | indent 2 }}
```

Then run `helm template`.

The result is not a valid YAML manifest, but this is a great debugging tool!

???

:EN:- Writing a basic Helm chart for the whole app
:FR:- Écriture d'un *chart* Helm simplifié
