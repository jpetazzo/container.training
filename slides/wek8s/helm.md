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

## Helm 2 / Helm 3

- Helm 3.0.0-alpha.1 was released May 15th, 2019

- Helm 2 is still the stable version (and will be for a while)

- Helm 3 removes Tiller (which simplifies permission management)

- There are many other smaller changes

  (see [Helm release changelog](https://github.com/helm/helm/releases/tag/v3.0.0-alpha.1) for the full list!)

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

## Repositories

- A repository is a remote server hosting a number of charts

  (any HTTP server can be a chart repository)

- Repositories are identified by a local name

- We can add as many repositories as we need

.exercise[

- List the repositories currently available:
  ```bash
  helm repo list
  ```

]

When we install Helm, it automatically configures a repository called `stable`.
<br/>
(Think of it like "Debian stable", for instance.)

---

## View available charts

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

## Viewing installed charts

- Helm keeps track of what we've installed

.exercise[

- List installed Helm charts:
  ```bash
  helm list
  ```

]

---

## Adding the WeWork repository

- The generic syntax is `helm repo add <nickname> <url>`

- We have a number of charts in Artifactory

- Since Artifactory is password-protected, we need to add `--username`

.exercise[

- Add the WeWork repository:
  ```bash
  helm repo add wework https://wework.jfrog.io/wework/helm/ --username=`jdoe`
  ```

- When prompted, provide your password

]

---

## Looking at the WeWork repository

- Let's have a look at the charts in this repository

.exercise[

- Search the repository name:
  ```bash
  helm search wework
  ```

]

---

## What's next?

- We could *install an existing application that has already been packaged*:

  `helm install wework/moonbase-climate-control`

  (sorry folks, that one doesn't exist [yet](https://disruption.medium.com/))

- We could *create a chart from scratch*:

  `helm create my-wonderful-new-app`

  (this creates a directory named `my-wonderful-new-app` with a barebones chart)

- We could do something in between: *install an app using a generic chart*

  (let's do that!)

---

## The wek8s generic service chart

- There is ~~an app~~ a chart for that!

.exercise[

- Look for `generic service`:
  ```bash
  helm search generic service
  ```

]

- The one that we want is `wework/wek8s-generic-service`

---

## Inspecting a chart

- Before installing a chart, we can check its description, README, etc.

.exercise[

- Look at all the available information:
  ```bash
  helm inspect wework/wek8s-generic-service
  ```

  (that's way too much information!)

- Look at the chart's description:
  ```bash
  helm inspect chart wework/wek8s-generic-service
  ```

]

---

## Using the wek8s generic chart

- We are going to download the chart's `values.yaml`

  (a file showing all the possible parameters for that chart)

- We are going to set the parameters we need, and discard the ones we don't

- Then we will install DockerCoins using that chart

---

## Dumping the chart's values

- Let's download the chart's `values.yaml`

- Then we will edit it to suit our needs

.exercise[

- Dump the chart's values to a YAML file:
  ```bash
  helm inspect values wework/wek8s-generic-service > values-rng.yaml
  ```

]

---

## Editing the chart's values

Edit `values-rng.yaml` and keep only this:

```yaml
appName: rng
replicaCount: 1
image:
  repository: dockercoins/rng
  tag: v0.1
service:
  enabled: true
  ports:
  - port: 80
    containerPort: 80
```

---

## Deploying the chart

- We can now install a *release* of the generic service chart using these values

- We will do that in a separate namespace (to avoid colliding with other resources)

.exercise[

- Switch to the `happyhelming` namespace:
  ```bash
  kubectl config set-context --current --namespace=happyhelming
  ```

- Install the `rng` release:
  ```bash
  helm install wework/wek8s-generic-service --name=rng --values=values-rng.yaml
  ```

]

Note: Helm will automatically create the namespace if it doesn't exist.

---

## Testing what we did

- If we were directly on the cluster, we could curl the service's ClusterIP

- But we're *not* on the cluster, so we will use `kubectl port-forward`

.exercise[

- Create a port forwarding to access port 80 of Deployment `rng`:
  ```bash
  kubectl port-forward deploy/rng 1234:80 &
  ```

- Confirm that RNG is running correctly:
  ```bash
  curl localhost:1234
  ```

- Terminate the port forwarder:
  ```bash
  kill %1
  ```

]

---

## Deploying the other services

- We need to create the values files for the other services:

  - `values-hasher.yaml` → almost identical (just change name and image)

  - `values-webui.yaml` → same

  - `values-redis.yaml` → same, but adjust port number

  - `values-worker.yaml` → same, but we can even remove the `service` part

- Then create all these services, using these YAML files

---

# Exercise — deploying an app with the wek8s Generic chart

.exercise[

- Create the 4 YAML files mentioned previously

- Install 4 Helm releases (one for each YAML file)

- What do we see in the logs of the worker?

]

---

## Troubleshooting

- We should see errors like this:
  ```
  Error -2 connecting to redis:6379. Name does not resolve.
  ```

- Why?

--

- Hint: `kubectl get services`

--

- Our services are named `redis-service`, `rng-service`, etc.

- Our code connects to `redis`, `rng`, etc.

- We need to drop the extra `-service`

---

## Editing a chart

- To edit a chart, we can push a new version to the repository

- But there is a much simpler and faster way

- We can use Helm to download the chart locally, make changes, apply them

- This also works when creating / developing a chart

  (we don't need to push it to the repository to try it out)

---

## Before diving in ...

.warning[Before editing or forking a generic chart like this one ...]

- Have a conversation with the authors of the chart

- Perhaps they can suggest other options, or adapt the chart

- We will edit the chart here, as a learning experience

- It may or may not be the right course of action in the general case!

---

## Download the chart

.exercise[

- Fetch the generic service chart to have a local, editable copy:
  ```bash
  helm fetch wework/wek8s-generic-service --untar
  ```

- This creates the directory `wek8s-generic-service`

- Have a look!

]

---

## Chart structure

Here is the structure of the directory containing our chart:

```
$ tree wek8s-generic-service/
wek8s-generic-service/
├── Chart.yaml
├── migrations
│   └── ...
├── README.md
├── templates
│   ├── _appContainer.yaml
│   ├── configmaps.yaml
│   ├── ... more YAML ...
│   ├── ... also, some .tpl files ...
│   ├── NOTES.txt
│   ├── ... more more YAML ...
│   └── ... and more more .tpl files
└── values.yaml
```

---

## Explanations

- `Chart.yaml` → chart short descriptipon and metadata

- `README.md` → longer description

- `values.yaml` → the file we downloaded earlier

- `templates/` → files in this directory will be *rendered* when the chart is installed

  - after rendering, each file is treated as a Kubernetes resource YAML file

  - ... except the ones starting with underscore (these will contain templates)

  - ... and except `NOTES.txt`, which is shown at the end of the deployment

Note: file extension doesn't really matter; the leading underscore does.

---

## Templates details

- Helm uses an extension of the Go template package

- This means that the files in `templates/` will be peppered with `{{ ... }}`

- For instance, this is an excerpt of `wek8s-generic-service/templates/service.yaml`:
  ```yaml
    metadata:
      name: {{ .Values.appName }}-service
      labels:
        app: {{ .Values.appName }}
  ```

- `{{ .Values.appName }}` will be replaced by the `appName` field from the values YAML

- For more details about the templating system, see the [Helm docs](https://helm.sh/docs/chart_template_guide/)

---

## Editing the templates

- Let's remove the trailing `-service` in the service definition

- Then, we will roll out that change

.exercise[

- Edit the file `wek8s-generic-service/templates/service.yaml`

- Remove the `-service` suffix

- Roll out the change to the `redis` release:
  ```bash
  helm upgrade redis wek8s-generic-service
  ```

]

- We used `upgrade` instead of `install` this time

- We didn't need to pass again the YAML file with the values

---

## Viewing our changes

- Normally, we "fixed" the `redis` service

- The `worker` should now be able to contact `redis`

.exercise[

- Check the logs of the `worker`:
  ```bash
  kubectl logs deploy/worker --tail 10 --follow
  ```

] 

- Alright, now we need to fix `rng`, `hasher`, and `webui` the same way

---

## Fixing the other services

- We don't need to download the chart or edit it again

- We can use the same chart for the other services

.exercise[

- Upgrade `rng`, `hasher`, and `webui` with the updated chart

- Confirm that the `worker` works correctly

  (it should say, "X units of work done ...")

]

---

## Extra steps

(If time permits ...)

.exercise[

- Setup a `port-forward` to view the web UI

- Scale the `worker` by updating the `replicaCount`

]

---

## Exposing a web application

- How do we expose the web UI with a proper URL?

- We will need to use an *Ingress*

- More on that later!

---

## If we wanted to submit our changes

- The source of the wek8s-generic-chart is in the following GitHub repository:

  https://github.com/WeConnect/WeK8s-charts

  (along with many other charts)

---

class: extra-details

## Good to know ...

- If we don't specify `--name` when running `helm install`, a name is generated

  (like `wisfhul-elephant` or `nihilist-alligator`)

- If we want to install-or-upgrade, we can use `helm upgrade --install`:

  `helm upgrade <name> <chart> --install --values=...`

- If we only want to set a few values, we can use `--set`, for instance:

  `helm upgrade redis wke8s-generic-chart --values=... --set=replicaCount=5`

  (we can use `--set` multiple times if needed)

.warning[If we specify `--set` without `--values`, it erases all the other values!]

---

class: extra-details

## If the first deployment fails

- If the first deployment of a release fails, it will be in an inconsistent state

- Further attempts to `helm install` or `helm upgrade` will fail

- To fix the problem, two solutions:

  - `helm delete --purge` that release

  - `helm upgrade --force` that release

- This only applies to the first deployment

  (i.e., Helm knows how to recover if a subsequent deployment fails)
