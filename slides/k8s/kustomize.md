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

(See the [kustomize glossary][glossary] for more definitions!)

[glossary]: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/

---

## What Kustomize *cannot* do

- By design, there are a number of things that Kustomize won't do

- For instance:

  - using command-line arguments or environment variables to generate a variant

  - overlays can only *add* resources, not *remove* them

- See the full list of [eschewed features](https://kubectl.docs.kubernetes.io/faq/kustomize/eschewedfeatures/) for more details

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

  - the `kustomize` CLI

  - opening the file with our favorite text editor

  - ~~web wizards like [Replicated Ship](https://www.replicated.com/ship/)~~ (deprecated)

- Let's see these in action!

---

## Working with the `kustomize` CLI

General workflow:

1. `kustomize create` to generate an empty `kustomization.yaml` file

2. `kustomize edit add resource` to add Kubernetes YAML files to it

3. `kustomize edit add patch` to add patches to said resources

4. `kustomize edit add ...` or `kustomize edit set ...` (many options!)

5. `kustomize build | kubectl apply -f-` or `kubectl apply -k .`

6. Repeat steps 4-5 as many times as necessary!

---

## Why work with the CLI?

- Editing manually can introduce errors and typos

- With the CLI, we don't need to remember the name of all the options and parameters

  (just add `--help` after any command to see possible options!)

- Make sure to install the completion and try e.g. `kustomize edit add [TAB][TAB]`

---

## `kustomize create`

.lab[

- Change to a new directory:
  ```bash
  mkdir ~/kustomcoins
  cd ~/kustomcoins
  ```

- Run `kustomize create` with the kustomcoins repository:
  ```bash
  kustomize create --resources https://github.com/jpetazzo/kubercoins
  ```

<!-- ```look at the files``` -->

- Run `kustomize build | kubectl apply -f-`

]

---

## `kubectl` integration

- Kustomize has been integrated in `kubectl` (since Kubernetes 1.14)

  - `kubectl kustomize` is an equivalent to `kustomize build`

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

## Adding labels

Labels can be added to all resources liks this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
...
commonLabels:
  app.kubernetes.io/name: dockercoins
```

Or with the equivalent CLI command:

```bash
kustomize edit add label app.kubernetes.io/name:dockercoins
```

---

## Use cases for labels

- Example: clean up components that have been removed from the kustomization

- Assuming that `commonLabels` have been set as shown on the previous slide:
  ```bash
    kubectl apply -k . --prune --selector app.kubernetes.io/name=dockercoins
  ```

- ... This command removes resources that have been removed from the kustomization

- Technically, resources with:

  - a `kubectl.kubernetes.io/last-applied-configuration` annotation

  - labels matching the given selector

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

or the CLI equivalent:

```bash
kustomize edit set replicas worker=5
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

## Updating images with the CLI

To add an entry in the `images:` section of the kustomization:

```bash
kustomize edit set image name=[newName][:newTag][@digest]
```

- `[]` denote optional parameters

- `:` and `@` are the delimiters used to indicate a field

Examples:
```bash
kustomize edit set image dockercoins/worker=ghcr.io/dockercoins/worker
kustomize edit set image dockercoins/worker=ghcr.io/dockercoins/worker:v0.2
kustomize edit set image dockercoins/worker=:v0.2
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
