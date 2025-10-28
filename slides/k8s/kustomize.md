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

- Integrated with `kubectl`

- No central index like the Artifact Hub (but is there a need for it?)

- *Some* modifications will be difficult to make

- 100% file-based (won't use command-line flags, environment variables...)

---

## Kustomize in a nutshell

- Get some valid YAML (our "resources")

- Write a *kustomization* (technically, a file named `kustomization.yaml`)

  - reference our resources

  - reference other kustomizations

  - add some *patches* and other *transformations*

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
resources:
- deployment.yaml
- service.yaml
- ingress.yaml
patches:
- path: scale-deployment.yaml
- path: ingress-hostname.yaml
```

On the next slide, let's see a more complex example ...

---

## A more complex Kustomization

.small[
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonAnnotations:
  last-commit-message: "Bump libfoo to version 1.2.3"
labels:
- pairs:
    last-commit-hash: "39bc2d"
resources:
- github.com/example/front?ref=tag-or-branch
- github.com/example/api?ref=tag-or-branch
- db/
- workers/
- ingress.yaml
- rbac.yaml
configMapGenerator:
- name: appconfig
  files:
  - global.conf
  - local.conf=prod.conf
patches:
- path: healthchecks.yaml
- path: resources-requests-and-limits.yaml
```
]

---

## Architecture

- Internally, Kustomize has three phases:

  - generators (=produce a bunch of YAML, e.g. by reading manifest files)

  - transformers (=transform/patch that YAML in various ways)

  - validators (=has the ability to stop the process is something's wrong)

- In the previous examples:

  - `resources` and `configMapGenerator` are generators

  - `commonAnnotations`, `labels`, `patches` are transformers

---

## Glossary

- A *base* is a kustomization that is referred to by other kustomizations

- An *overlay* is a kustomization that refers to other kustomizations

- A kustomization can be both a base and an overlay at the same time

  (a kustomization can refer to another, which can refer to a third)

- A *variant* is the final outcome of applying bases + overlays

(See the [kustomize glossary][glossary] for more definitions!)

[glossary]: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/

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

- No technical difference; these are just different use-cases!

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

- Kustomize is now officially part of [sig-cli]

- `kubectl` is usually in sync with recent versions of Kustomize

  (but it can still lag behind a bit, so some features might not be available!)

[sig-cli]: https://github.com/kubernetes/community/blob/master/sig-cli/README.md

---

## Kustomize features

- A good starting point for Kustomize features is [the Kustomization File reference](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)

- Unfortunately, the Kustomize documentation is far from perfect

- Some features are undocumented

- Some features are deprecated / replaced by others

  (but that's not well indicated in the docs; e.g. `commonLabels`)

- Some features are documented but not released yet

  (e.g. regex selectors in `replacements` as of October 2025)

---

## Kustomization basics

- `bases` (deprecated), `resources`

  *include YAML manifests*

- `buildMetadata`

  *automatically generate interesting labels / annotations*

- `commonAnnotations`, `commonLabels`, `labels`

  *add custom labels / annotations to all resources*

- `configMapGenerator`, `secretGenerator`, `generatorOptions`

  *generate ConfigMaps and Secrets; appending a hash suffix to their name*

---

## Transforming resources

- `patches` `patchesJson6902`, `patchesStrategicMerge`

  - perform (almost) arbitrary modifications to resources

  - can be used to remove fields or even entire resources

  - patches can be in separate files, or inlined within Kustomization file

  - patches can apply to a specific resource, or to selected resources

- `images`, `namePrefix`, `namespace`, `nameSuffix`, `replicas`

  - helpers for basic modifications; concise and easy to use, but limited

---

## More transformations

- `replacements`

  - update individual fields (a bit like patches)

  - can also do substring updates (e.g. replace an image registry)

  - can copy a field from a place to another (e.g. a whole container spec)

  - can apply to individual resources or to selected resources

  - resources can also be *filtered out* (to be excluded from replacement)

---

## Teach Kustomize new tricks

- `crds` = make Kustomize aware of e.g. ConfigMap fields in CRDs

- `openapi` = give a schema to teach Kustomize about merge keys etc.

- `sortOptions` = output resources in a specific order

- `helmCharts` = evaluate a Helm chart template

  (only available with `--enable-helm` flag; not standard / GA yet!)

- `vars` = define variables and reuse them elsewhere

  (limited to some specific fields; ...actually, it's being deprecated already!)

- `components` = somewhat similar to an "include"

  (points to a "component" and invoke all its generators and transformers)

---

## Remote bases

- Kustomize can also use bases that are remote git repositories

- Example:

  https://github.com/kubernetes-sigs/kustomize//examples/multibases/?ref=v3.3.1

- See [remoteBuild.md](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/remoteBuild.md) for details about remote targets URL format

- Note that this only works for kustomizations, not individual resources

  (the specified repository or directory must contain a `kustomization.yaml` file)

---

## What Kustomize *cannot* do

- By design, there are a number of things that Kustomize won't do

- For instance:

  - using command-line arguments or environment variables to generate a variant

  - overlays can only *add* resources, not *remove* them¹

- See the full list of [eschewed features](https://kubectl.docs.kubernetes.io/faq/kustomize/eschewedfeatures/) for more details

.footnote[¹That's actually not true; patches can remove resources.]

---

## Changing image references

- We're going to see a few different ways to change image references

- Let's assume that our app uses multiple images:

  `redis`, `dockercoins/hasher`, `dockercoins/worker`...

- We want to update the `dockercoins/*` images to use a registry mirror

  (e.g. `ghcr.io/dockercoins/*`)

- We don't want to touch the other images

---

## Changing images with the CLI

We can use the following CLI command:

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

This will add entries in the `images:` section of the kustomization.

---

## Changing images with `images:`

Here are a few examples of the `images:` Kustomization directive:

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

## `images:` in practice

This is what we would need for our app:

```yaml
- name: dockercoins/hasher
  newName: ghcr.io/dockercoins/hasher
- name: dockercoins/rng
  newName: ghcr.io/dockercoins/rng
- name: dockercoins/webui
  newName: ghcr.io/dockercoins/webui
- name: dockercoins/worker
  newName: ghcr.io/dockercoins/worker
```

It works, but requires two lines per image. Can we do better? 🤔

---

## `images:`, pros and cons

- Very convenient when the same image appears multiple times

- Very convenient to define tags (or pin to hashes) outside of the main YAML

- Doesn't support wildcard or generic substitutions:

  - cannot "replace `dockercoins/*` with `ghcr.io/dockercoins/*`"

  - cannot "tag all `dockercoins/*` with `v0.2`"

- Only patches "well-known" image fields (won't work with CRDs referencing images)

- If our app uses 4 images, we'll need 4 `images:` section in the Kustomization file

---

## `PrefixSuffixTransformer`

- Internally, the `namePrefix` directive relies on a `PrefixSuffixTransformer`

- By default, that transformer acts on `metadata.name`

- It can be invoked manually and configured to act on other fields

  (for instance, `spec.template.spec.containers.image` in a Deployment manifest)

---

## `PrefixSuffixTransformer` in action

```yaml
@@INCLUDE[k8s/kustomize-examples/registry-with-prefix-transformer/microservices/kustomization.yaml]
```

- However, this will transform **all** Deployments!

- Or rather, all resources with a `spec.template.spec.containers.image` field

---

## Limiting `PrefixSuffixTransformer`

<!-- ##VERSION## -->

- `PrefixSuffixTransformer` applies to *all* resources

  (as of Kustomize 5.7 (October 2025), there is no way to specify a filter)

- One workaround:

  - break down the app in multiple Kustomizations

  - in one Kustomization, put the components that need to be transformed

  - put the other components in another Kustomization

- Not great if multiple transformations need to be applied on different resources

---

## `replacements`

- Allows to entirely replace a field

- Can also replace *part* of a field (using some delimiter, e.g. `/` for images)

- Replacements can apply to *selected* resources

- Let's see an example!

---

## `replacements` in action

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- dockercoins.yaml
replacements:
- sourceValue: ghcr.io/dockercoins
  targets:
  - select:
      kind: Deployment
      labelSelector: "app in (hasher,rng,webui,worker)"
    fieldPaths:
    - spec.template.spec.containers.*.image
    options:
      delimiter: "/"
      index: 0
```

(Note the different `fieldPath` format, compared to the earlier transformer!)

---

## Discussion

- There are multiple ways to rewrite image references to use a registry mirror

- They all have pros and cons

- Main problem: they require to enumerate the resources that we want to transform

  (or to split them in a separate Kustomization)

- No (easy?) way to do something like:

  "Replace all images starting by `dockercoins/` with `ghcr.io/dockercoins/`"

---

## Inconsistencies

- Sometimes it's possible to filter / select resources, sometimes not

- When it's possible, it's not always done the same way

- Field paths are also different in different places:

  `/spec/template/spec/containers/0/image` in JSON patches

  `spec.template.spec.containers.0.image` in replacements' `fieldPaths`

  `spec/template/spec/containers/image` in transformers' `fieldSpecs`

  `.spec.template.spec.containers[].image` with tools like `jq`

- `fieldPaths` also have interesting extensions, like:

  `spec.template.spec.containers.[name=hello].image`

---

## Conclusions

- It's possible to do a lot of transformations with Kustomize

- In complex scenarios, it can quickly becomes a maintenance nightmare

- One possible strategy:

  - keep each Kustomization as simple as possible

  - compose multiple Kustomizations together

- See [this kustomization][ollama-with-sidecar] for a creative example with sidecars and more

- See [that kustomization][flux-kustomization] for an example adding command line flags to controllers

[ollama-with-sidecar]: https://github.com/jpetazzo/container.training/blob/main/k8s/admission-configuration.yaml
[flux-kustomization]: https://github.com/fluxcd/flux2-multi-tenancy/blob/main/clusters/production/flux-system/kustomization.yaml

???

:EN:- Packaging and running apps with Kustomize
:FR:- *Packaging* d'applications avec Kustomize
