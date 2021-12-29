# Kustomize

- Kustomize lets us transform Kubernetes resources:

  *YAML + kustomize → new YAML*

- Starting point = valid resource files

  (i.e. something that we could load with `kubectl apply -f`)

- Recipe = a *kustomization* file

  (describing how to transform the resources)

- Result = new resource files

  (that we can load with `kubectl apply -f`)

---

## Pros and cons

- Relatively easy to get started

  (just get some existing YAML files)

- Easy to leverage existing "upstream" YAML files

  (or other *kustomizations*)

- Somewhat integrated with `kubectl`

  (but only "somewhat" because of version discrepancies)

- Less complex than e.g. Helm, but also less powerful

- No central index like the Artifact Hub (but is there a need for it?)

---

## Kustomize in a nutshell

- Get some valid YAML (our "resources")

- Write a *kustomization* (technically, a file named `kustomization.yaml`)

  - reference our resources

  - reference other kustomizations

  - add some *patches*

  - ...

- Use that kustomization either with `kustomize build` or `kubectl apply -k`

- Write new kustomizations referencing the first one to handle minor differences

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

## A more complex Kustomization

.small[
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonAnnotations:
  mood: 😎
commonLabels:
  add-this-to-all-my-resources: please
namePrefix: prod-
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
]

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

- Kustomize can also use bases that are remote git repositories

- Examples:

  github.com/jpetazzo/kubercoins (remote git repository)

  github.com/jpetazzo/kubercoins?ref=kustomize (specific tag or branch)

- Note that this only works for kustomizations, not individual resources

  (the specified repository or directory must contain a `kustomization.yaml` file)

---

class: extra-details

## Hashicorp go-getter

- Some versions of Kustomize support additional forms for remote resources

- Examples:

  https://releases.hello.io/k/1.0.zip (remote archive)

  https://releases.hello.io/k/1.0.zip//some-subdir (subdirectory in archive)

- This relies on [hashicorp/go-getter](https://github.com/hashicorp/go-getter#url-format)

- ... But it prevents Kustomize inclusion in `kubectl`

- Avoid them!

- See [kustomize#3578](https://github.com/kubernetes-sigs/kustomize/issues/3578) for details

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

.lab[

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

.lab[

- Create a new namespace:
  ```bash
  kubectl create namespace kustomcoins
  ```

- Deploy DockerCoins:
  ```bash
  kubectl apply -f rendered.yaml --namespace=kustomcoins
  ```

- Or, with Kubernetes 1.14, we can also do this:
  ```bash
  kubectl apply -k overlays/ship --namespace=kustomcoins
  ```

]

---

## Checking our new copy of DockerCoins

- We can check the worker logs, or the web UI

.lab[

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

## `kubectl` integration

- Kustomize has been integrated in `kubectl` (since Kubernetes 1.14)

  - `kubectl kustomize` can apply a kustomization

  - commands that use `-f` can also use `-k` (`kubectl apply`/`delete`/...)

- The `kustomize` tool is still needed if we want to use `create`, `edit`, ...

- Kubernetes 1.14 to 1.20 uses Kustomize 2.0.3

- Kubernetes 1.21 jumps to Kustomize 4.1.2

- Future versions should track Kustomize updates more closely

---

class: extra-details

## Differences between 2.0.3 and later

- Kustomize 2.1 / 3.0 deprecates `bases` (they should be listed in `resources`)

  (this means that "modern" `kustomize edit add resource` won't work with "old" `kubectl apply -k`)

- Kustomize 2.1 introduces `replicas` and `envs`

- Kustomize 3.1 introduces multipatches

- Kustomize 3.2 introduce inline patches in `kustomization.yaml`

- Kustomize 3.3 to 3.10 is mostly internal refactoring

- Kustomize 4.0 drops go-getter again

- Kustomize 4.1 allows patching kind and name

---

## Scaling

Instead of using a patch, scaling can be done like this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
...
replicas:
- name: worker
  count: 5
```

It will automatically work with Deployments, ReplicaSets, StatefulSets.

(For other resource types, fall back to a patch.)

---

## Updating images

Instead of using patches, images can be changed like this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
...
images:
- name: postgres
  newName: harbor.enix.io/my-postgres
- name: dockercoins/worker
  newTag: v0.2
- name: dockercoins/hasher
  newName: registry.dockercoins.io/hasher
  newTag: v0.2
- name: alpine
  digest: sha256:24a0c4b4a4c0eb97a1aabb8e29f18e917d05abfe1b7a7c07857230879ce7d3d3
```

---

## Updating images, pros and cons

- Very convenient when the same image appears multiple times

- Very convenient to define tags (or pin to hashes) outside of the main YAML

- Doesn't support wildcard or generic substitutions:

  - cannot "replace `dockercoins/*` with `ghcr.io/dockercoins/*`"

  - cannot "tag all `dockercoins/*` with `v0.2`"

- Only patches "well-known" image fields (won't work with CRDs referencing images)

- Helm can deal with these scenarios, for instance:
  ```yaml
  image: {{ .Values.registry }}/worker:{{ .Values.version }}
  ```

---

## Advanced resource patching

The example below shows how to:

- patch multiple resources with a selector (new in Kustomize 3.1)
- use an inline patch instead of a separate patch file (new in Kustomize 3.2)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
...
patches:
- patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: alpine
  target:
    kind: Deployment
    labelSelector: "app"
```

(This replaces all images of Deployments matching the `app` selector with `alpine`.)

---

## Advanced resource patching, pros and cons

- Very convenient to patch an arbitrary number of resources

- Very convenient to patch any kind of resource, including CRDs

- Doesn't support "fine-grained" patching (e.g. image registry or tag)

- Once again, Helm can do it:
  ```yaml
  image: {{ .Values.registry }}/worker:{{ .Values.version }}
  ```

---

## Differences with Helm

- Helm charts generally require more upfront work

  (while kustomize "bases" are standard Kubernetes YAML)

- ... But Helm charts are also more powerful; their templating language can:

  - conditionally include/exclude resources or blocks within resources

  - generate values by concatenating, hashing, transforming parameters

  - generate values or resources by iteration (`{{ range ... }}`)

  - access the Kubernetes API during template evaluation

  - [and much more](https://helm.sh/docs/chart_template_guide/)

???

:EN:- Packaging and running apps with Kustomize
:FR:- *Packaging* d'applications avec Kustomize
