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

- It is used to find, install, upgrade *charts*

- A chart is an archive containing templatized YAML bundles

- Charts are versioned

- Charts can be stored on private or public repositories

---

## Differences between charts and packages

- A package (deb, rpm...) contains binaries, libraries, etc.

- A chart contains YAML manifests

  (the binaries, libraries, etc. are in the images referenced by the chart)

- On most distributions, a package can only be installed once

  (installing another version replaces the installed one)

- A chart can be installed multiple times

- Each installation is called a *release*

- This allows to install e.g. 10 instances of MongoDB

  (with potentially different versions and configurations)

---

class: extra-details

## Wait a minute ...

*But, on my Debian system, I have Python 2 **and** Python 3.
<br/>
Also, I have multiple versions of the Postgres database engine!*

Yes!

But they have different package names:

- `python2.7`, `python3.8`

- `postgresql-10`, `postgresql-11`

Good to know: the Postgres package in Debian includes
provisions to deploy multiple Postgres servers on the
same system, but it's an exception (and it's a lot of
work done by the package maintainer, not by the `dpkg`
or `apt` tools).

---

## Helm 2 vs Helm 3

- Helm 3 was released [November 13, 2019](https://helm.sh/blog/helm-3-released/)

- Charts remain compatible between Helm 2 and Helm 3

- The CLI is very similar (with minor changes to some commands)

- The main difference is that Helm 2 uses `tiller`, a server-side component

- Helm 3 doesn't use `tiller` at all, making it simpler (yay!)

---

class: extra-details

## With or without `tiller`

- With Helm 3:

  - the `helm` CLI communicates directly with the Kubernetes API

  - it creates resources (deployments, services...) with our credentials

- With Helm 2:

  - the `helm` CLI communicates with `tiller`, telling `tiller` what to do

  - `tiller` then communicates with the Kubernetes API, using its own credentials

- This indirect model caused significant permissions headaches

  (`tiller` required very broad permissions to function)

- `tiller` was removed in Helm 3 to simplify the security aspects

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
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 \
  | bash
  ```

]

(To install Helm 2, replace `get-helm-3` with `get`.)

---

class: extra-details

## Only if using Helm 2 ...

- We need to install Tiller and give it some permissions

- Tiller is composed of a *service* and a *deployment* in the `kube-system` namespace

- They can be managed (installed, upgraded...) with the `helm` CLI

.exercise[

- Deploy Tiller:
  ```bash
  helm init
  ```

]

At the end of the install process, you will see:

```
Happy Helming!
```

---

class: extra-details

## Only if using Helm 2 ...

- Tiller needs permissions to create Kubernetes resources

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

## Charts and repositories

- A *repository* (or repo in short) is a collection of charts

- It's just a bunch of files

  (they can be hosted by a static HTTP server, or on a local directory)

- We can add "repos" to Helm, giving them a nickname

- The nickname is used when referring to charts on that repo

  (for instance, if we try to install `hello/world`, that
  means the chart `world` on the repo `hello`; and that repo
  `hello` might be something like https://blahblah.hello.io/charts/)

---

## Managing repositories

- Let's check what repositories we have, and add the `stable` repo

  (the `stable` repo contains a set of official-ish charts)

.exercise[

- List our repos:
  ```bash
  helm repo list
  ```

- Add the `stable` repo:
  ```bash
  helm repo add stable https://kubernetes-charts.storage.googleapis.com/
  ```

]

Adding a repo can take a few seconds (it downloads the list of charts from the repo).

It's OK to add a repo that already exists (it will merely update it).

---

## Search available charts

- We can search available charts with `helm search`

- We need to specify where to search (only our repos, or Helm Hub)

- Let's search for all charts mentioning tomcat!

.exercise[

- Search for tomcat in the repo that we added earlier:
  ```bash
  helm search repo tomcat
  ```

- Search for tomcat on the Helm Hub:
  ```bash
  helm search hub tomcat
  ```

]

[Helm Hub](https://hub.helm.sh/) indexes many repos, using the [Monocular](https://github.com/helm/monocular) server.

---

## Charts and releases

- "Installing a chart" means creating a *release*

- We need to name that release

  (or use the `--generate-name` to get Helm to generate one for us)

.exercise[

- Install the tomcat chart that we found earlier:
  ```bash
  helm install java4ever stable/tomcat
  ```

- List the releases:
  ```bash
  helm list
  ```

]

---

class: extra-details

## Searching and installing with Helm 2

- Helm 2 doesn't have support for the Helm Hub

- The `helm search` command only takes a search string argument

  (e.g. `helm search tomcat`)

- With Helm 2, the name is optional:

  `helm install stable/tomcat` will automatically generate a name

  `helm install --name java4ever stable/tomcat` will specify a name

---

## Viewing resources of a release

- This specific chart labels all its resources with a `release` label

- We can use a selector to see these resources

.exercise[

- List all the resources created by this release:
  ```bash
  kubectl get all --selector=release=java4ever
  ```

]

Note: this `release` label wasn't added automatically by Helm.
<br/>
It is defined in that chart. In other words, not all charts will provide this label.

---

## Configuring a release

- By default, `stable/tomcat` creates a service of type `LoadBalancer`

- We would like to change that to a `NodePort`

- We could use `kubectl edit service java4ever-tomcat`, but ...

  ... our changes would get overwritten next time we update that chart!

- Instead, we are going to *set a value*

- Values are parameters that the chart can use to change its behavior

- Values have default values

- Each chart is free to define its own values and their defaults

---

## Checking possible values

- We can inspect a chart with `helm show` or `helm inspect`

.exercise[

- Look at the README for tomcat:
  ```bash
  helm show readme stable/tomcat
  ```

- Look at the values and their defaults:
  ```bash
  helm show values stable/tomcat
  ```

]

The `values` may or may not have useful comments.

The `readme` may or may not have (accurate) explanations for the values.

(If we're unlucky, there won't be any indication about how to use the values!)

---

## Setting values

- Values can be set when installing a chart, or when upgrading it

- We are going to update `java4ever` to change the type of the service

.exercise[

- Update `java4ever`:
  ```bash
  helm upgrade java4ever stable/tomcat --set service.type=NodePort
  ```

]

Note that we have to specify the chart that we use (`stable/tomcat`),
even if we just want to update some values.

We can set multiple values. If we want to set many values, we can use `-f`/`--values` and pass a YAML file with all the values.

All unspecified values will take the default values defined in the chart.

---

## Connecting to tomcat

- Let's check the tomcat server that we just installed

- Note: its readiness probe has a 60s delay

  (so it will take 60s after the initial deployment before the service works)

.exercise[

- Check the node port allocated to the service:
  ```bash
  kubectl get service java4ever-tomcat
  PORT=$(kubectl get service java4ever-tomcat -o jsonpath={..nodePort})
  ```

- Connect to it, checking the demo app on `/sample/`:
  ```bash
  curl localhost:$PORT/sample/
  ```

]
