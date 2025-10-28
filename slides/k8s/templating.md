# Manifest Templating

- In the Kubernetes ecosystem, we often use tools like Helm or Kustomize

- These tools are deeply integrated with CD solutions like Flux or Argo

- What do Helm and Kustomize do?

- When do we need to learn them?

- What's the difference between them?

---

## A typical Kubernetes learning curve

1. Create resources with one-line commands

   (`kubectl run`, `kubectl create deployment`, `kubectl expose`...)

2. Author YAML manifests to describe these resources

3. Create resources with `kubectl apply -f`, `kubectl create -f`...

4. Combine multiple resources in a single YAML files

   (making it convenient to deploy entire stacks)

5. Tweak these YAML manifests to adapt them between dev, prod, etc.

   (e.g.: number of replicas, image version to use, features to enable...)

*In this section, we're going to talk about step 5 specifically!*

---

## How can we tweak YAML manifests?

- Standard UNIX tools

  (e.g.: `sed`, `envsubst`... after all, YAML manifests are just text!)

- Tools designed to evaluate text templates

  (e.g.: [gomplate]...)

- Tools designed to manipulate structured data like JSON or YAML

  (e.g.: [jsonnet], [CUE], [ytt]...)

- Tools designed specifically to handle Kubernetes manifests

  (e.g.: Helm, Kustomize...)

[gomplate]: https://github.com/hairyhenderson/gomplate
[jsonnet]: https://jsonnet.org/
[CUE]: https://github.com/cue-labs/cue-by-example/tree/main/003_kubernetes_tutorial
[ytt]: https://carvel.dev/ytt/

---

## Standard UNIX tools - `sed`

- Create YAML files with placeholders, e.g.:
  ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: front
    spec:
      rules:
      - host: HOSTNAME
        ...
  ```

- Replace the placeholders:
  ```bash
  sed 's/HOSTNAME/www.example.com/g' < ingress.yaml | kubectl apply -f-
  ```

- Placeholders can be delimited to avoid ambiguity (e.g. use `@@HOSTNAME@@`)

---

## Standard UNIX tools - `envsubst`

- Create YAML files with environment variables, e.g.:
  ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: front
    spec:
      rules:
      - host: ${HOSTNAME}
        ...
  ```

- Evaluate the environment variables:
  ```bash
  HOSTNAME=www.example.com envsubst < ingress.yaml | kubectl apply -f-
  ```

- Very convenient in pipelines where our variables are already in the environment!

---

## Text templating tools

- These are very rarely used

- ...Because Helm already relies on a text templating engine!

- Other engines are usually very similar to Helm's

  (in other words: they wouldn't provide enough value vs. Helm)

- Helm has a lot of interesting Kubernetes-specific features

- So if we want to do text templating, we'll likely use Helm

---

## Tools like jsonnet, CUE, ytt

- Jsonnet: generic tool to manipulate JSON data structures

  *was popular in the early days of Kubernetes, before the rise of Helm and Kustomize*

- CUE: generic engine for data validation, templating, configuration...

  *powerful, but steeper learning curve*

- ytt: YAML Templating Tool

  *interesting for all YAML manifests (not just Kubernetes)*

- Some teams are using these tools; feel free to have a look at them!

---

## Helm

*Combines multiple elements!*

- Text templating engine

  (based on Go's [text/template] + [Sprig] + other Kubernetes )

- Templates can use "values"

  (input parameters than can be provided e.g. in a structured YAML file)

- Helm will manage application lifecycle, like a package manager

  (=apply manifests, keep track of what's installed, give uninstall/rollback...)

- Huge library of Helm "charts" available through the [Artifact Hub]

[text/template]: https://pkg.go.dev/text/template
[Sprig]: https://masterminds.github.io/sprig/
[Artifact Hub]: https://artifacthub.io/

---

## Kustomize

- "Kubernetes native configuration management"

- Apply transformations to existing resources

  (keep YAML manifests as-is instead of "templatizing" them)

- Manipulate data structures, not YAML text representations

- Integrated with `kubectl` (with `kubectl ... -k`)

---

## Helm vs Kustomize

- Installing Helm charts:

  - huge library available on the Artifact Hub
  - relatively easy to get started
  - hard to tweak

- Authoring Helm charts:

  - manipulating YAML text representations = 💩
  - but (almost) everything is possible!
  - complex setups can take a lot of work

- Kustomize:

  - easy to get started
  - doesn't require to rewrite YAML manifests
  - can apply (almost) arbitrary patches to resources

---

## Which one is best?

- Both have their use-cases

- Plain YAML is great for simple scenarios

  (when there isn't anything to configure / tweak)

- Helm is great for complex situations

  (lots of settings and/or settings with deep cross-cutting changes)

- Kustomize is great when we can't/won't use a Helm chart

  (3rd party software without a Helm chart; or if we don't want to write one)

---

## Do we need to learn both?

*Personal recommendations / suggestions...*

- Learn how to *install* Helm charts

  (a lot of Kubernetes software is available that way)

- Learn how to do basic stuff with Kustomize

  (e.g. apply simple patches / replacements on existing YAML)

- If you want to distribute software for Kubernetes: probably learn to *write* charts

  (a lot of people will expect your stuff to be installable / configurable with Helm)

- For internal use: pick either Helm or Kustomize and learn it well!

  (check which one will work best for you depending on your use-case)

---

class: extra-details

## What about Terraform, Ansible...?

- Can we use "classic" tooling with Kubernetes?

- Yes!

- Example: Terraform / OpenTofu have "providers" for Kubernetes 

  ([opentofu/kubernetes], [opentofu/helm])

- This lets you write HCL instead of YAML

- Kubernetes resources can integrate nicely with other TF resources

- This is great if you are already very invested in TF

- Also convenient if you're already managing e.g. secrets with TF

- Similar situation with Ansible and other tools

[opentofu/kubernetes]: https://search.opentofu.org/provider/opentofu/kubernetes/latest
[opentofu/helm]: https://search.opentofu.org/provider/opentofu/helm/latest
???

:EN:- Beyond static YAML
:EN:- Comparison of YAML templating tools

:FR:- Au-delà du YAML statique
:FR:- Analyse d'outils de production de YAML
