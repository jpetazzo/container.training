# Kustomize

- Kustomize lets us transform YAML files representing Kubernetes resources

- The original YAML files are valid resource files

  (e.g. they can be loaded with `kubectl apply -f`)

- They are left untouched by Kustomize

- Kustomize lets us define *kustomizations*

- A *kustomization* is conceptually similar to a *layer*

- Technically, a *kustomization* is a file named `kustomization.yaml`

  (or a directory containing that files + additional files)

---

## What's in a kustomization

- A kustomization can do any combination of the following:

  - include other kustomizations

  - include Kubernetes resources defined in YAML files

  - patch Kubernetes resources (change values)

  - add labels or annotations to all resources

  - specify ConfigMaps and Secrets from literal values or local files

(... And a few more advanced features that we won't cover today!)

---

## A simple kustomization

This features a Deployment, Service, and Ingress (in separate files),
and a couple of patches (to change the number of replicas and the hostname
used in the Ingress).

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
patchesStrategicMerge:
- scale-deployment.yaml
- ingress-hostname.yaml
resources:
- deployment.yaml
- service.yaml
- ingress.yaml
```

On the next slide, let's see a more complex example ...

---

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonLabels:
  add-this-to-all-my-resources: please
patchesStrategicMerge:
- prod-scaling.yaml
- prod-healthchecks.yaml
bases:
- api/
- frontend/
- db/
- github.com/example/app?ref=tag-or-branch
resources:
- ingress.yaml
- permissions.yaml
configMapGenerator:
- name: appconfig
  files:
  - global.conf
  - local.conf=prod.conf
```

---

## Glossary

- A *base* is a kustomization that is referred to by other kustomizations

- An *overlay* is a kustomization that refers to other kustomizations

- A kustomization can be both a base and an overlay at the same time

  (a kustomization can refer to another, which can refer to a third)

- A *patch* describes how to alter an existing resource

  (e.g. to change the image in a Deployment; or scaling parameters; etc.)

- A *variant* is the final outcome of applying bases + overlays

(See the [kustomize glossary](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/glossary.md) for more definitions!)

---

## What Kustomize *cannot* do

- By design, there are a number of things that Kustomize won't do

- For instance:

  - using command-line arguments or environment variables to generate a variant

  - overlays can only *add* resources, not *remove* them

- See the full list of [eschewed features](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/eschewedFeatures.md) for more details

---

## Kustomize workflows

- The Kustomize documentation proposes two different workflows

- *Bespoke configuration*

   - base and overlays managed by the same team

- *Off-the-shelf configuration* (OTS)

  - base and overlays managed by different teams

  - base is regularly updated by "upstream" (e.g. a vendor)

  - our overlays and patches should (hopefully!) apply cleanly

  - we may regularly update the base, or use a remote base

---

## Remote bases

- Kustomize can fetch remote bases using Hashicorp go-getter library

- Examples:

  github.com/jpetazzo/kubercoins (remote git repository)

  github.com/jpetazzo/kubercoins?ref=kustomize (specific tag or branch)

  https://releases.hello.io/k/1.0.zip (remote archive)

  https://releases.hello.io/k/1.0.zip//some-subdir (subdirectory in archive)

- See [hashicorp/go-getter URL format docs](https://github.com/hashicorp/go-getter#url-format) for more examples

---

## Managing `kustomization.yaml`

- There are many ways to manage `kustomization.yaml` files, including:

  - web wizards like [Replicated Ship](https://www.replicated.com/ship/)

  - the `kustomize` CLI

  - opening the file with our favorite text editor

- Let's see these in action!

---

## An easy way to get started with Kustomize

- We are going to use [Replicated Ship](https://www.replicated.com/ship/) to experiment with Kustomize

- The [Replicated Ship CLI](https://github.com/replicatedhq/ship/releases) has been installed on our clusters

- Replicated Ship has multiple workflows; here is what we will do:

  - initialize a Kustomize overlay from a remote GitHub repository

  - customize some values using the web UI provided by Ship

  - look at the resulting files and apply them to the cluster

---

## Getting started with Ship

- We need to run `ship init` in a new directory

- `ship init` requires a URL to a remote repository containing Kubernetes YAML

- It will clone that repository and start a web UI

- Later, it can watch that repository and/or update from it

- We will use the [jpetazzo/kubercoins](https://github.com/jpetazzo/kubercoins) repository

  (it contains all the DockerCoins resources as YAML files)

---

## `ship init`

.exercise[

- Change to a new directory:
  ```bash
  mkdir ~/kustomcoins
  cd ~/kustomcoins
  ```

- Run `ship init` with the kustomcoins repository:
  ```bash
  ship init https://github.com/jpetazzo/kubercoins
  ```

<!-- ```wait Open browser``` -->

]

---

## Access the web UI

- `ship init` tells us to connect on `localhost:8800`

- We need to replace `localhost` with the address of our node

  (since we run on a remote machine)

- Follow the steps in the web UI, and change one parameter

  (e.g. set the number of replicas in the worker Deployment)

- Complete the web workflow, and go back to the CLI

---

## Inspect the results

- Look at the content of our directory

- `base` contains the kubercoins repository + a `kustomization.yaml` file

- `overlays/ship` contains the Kustomize overlay referencing the base + our patch(es)

- `rendered.yaml` is a YAML bundle containing the patched application

- `.ship` contains a state file used by Ship

---

## Using the results

- We can `kubectl apply -f rendered.yaml`

  (on any version of Kubernetes)

- Starting with Kubernetes 1.14, we can apply the overlay directly with:
  ```bash
  kubectl apply -k overlays/ship
  ```

- But let's not do that for now!

- We will create a new copy of DockerCoins in another namespace

---

## Deploy DockerCoins with Kustomize

.exercise[

- Create a new namespace:
  ```bash
  kubectl create namespace kustomcoins
  ```

- Deploy DockerCoins:
  ```bash
  kubectl apply -f rendered.yaml --namespace=kustomcoins
  ```

- Or, with Kubernetes 1.14, you can also do this:
  ```bash
  kubectl apply -k overlays/ship --namespace=kustomcoins
  ```

]

---

## Checking our new copy of DockerCoins

- We can check the worker logs, or the web UI

.exercise[

- Retrieve the NodePort number of the web UI:
  ```bash
  kubectl get service webui --namespace=kustomcoins
  ```

- Open it in a web browser

- Look at the worker logs:
  ```bash
  kubectl logs deploy/worker --tail=10 --follow --namespace=kustomcoins
  ```

<!--
```wait units of work done``` 
```key ^C```
-->

]

Note: it might take a minute or two for the worker to start.

---

## Working with the `kustomize` CLI

- This is another way to get started

- General workflow:

  `kustomize create` to generate an empty `kustomization.yaml` file

  `kustomize edit add resource` to add Kubernetes YAML files to it

  `kustomize edit add patch` to add patches to said resources

  `kustomize build | kubectl apply -f-` or `kubectl apply -k .`

---

## `kubectl apply -k`

- Kustomize has been integrated in `kubectl`

- The `kustomize` tool is still needed if we want to use `create`, `edit`, ...

- Also, warning: `kubectl apply -k` is a slightly older version than `kustomize`!

- In recent versions of `kustomize`, bases can be listed in `resources`

  (and `kustomize edit add base` will add its arguments to `resources`)

- `kubectl apply -k` requires bases to be listed in `bases`

  (so after using `kustomize edit add base`, we need to fix `kustomization.yaml`)

---

## Differences with Helm

- Helm charts use placeholders `{{ like.this }}`

- Kustomize "bases" are standard Kubernetes YAML

- It is possible to use an existing set of YAML as a Kustomize base

- As a result, writing a Helm chart is more work ...

- ... But Helm charts are also more powerful; e.g. they can:

  - use flags to conditionally include resources or blocks

  - check if a given Kubernetes API group is supported

  - [and much more](https://helm.sh/docs/chart_template_guide/)

???

:EN:- Packaging and running apps with Kustomize
:FR:- *Packaging* d'applications avec Kustomize

