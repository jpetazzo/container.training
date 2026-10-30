# Managing stacks with Helm

- Helm is a (kind of!) package manager for Kubernetes

- We can use it to:

  - find existing packages (called "charts") created by other folks

  - install these packages, configuring them for our particular setup

  - package our own things (for distribution or for internal use)

  - manage the lifecycle of these installs (rollback to previous version etc.)

- It's a "CNCF graduate project", indicating a certain level of maturity

  (more on that later)

---

## Helm features

- With Helm, we create "charts"

- These charts can be used internally or distributed publicly

- Public charts can be indexed through the [Artifact Hub](https://artifacthub.io/)

- This gives us a way to find and install other folks' charts

- Helm also gives us ways to manage the lifecycle of what we install:

  - keep track of what we have installed

  - upgrade versions, change parameters, roll back, uninstall

- Furthermore, even if it's not "the" standard, it's definitely "a" standard!

---

## CNCF graduation status

- On April 30th 2020, Helm was the 10th project to *graduate* within the CNCF

  (alongside Containerd, Prometheus, and Kubernetes itself)

- This is an acknowledgement by the CNCF for projects that

  *demonstrate thriving adoption, an open governance process,
  <br/>
  and a strong commitment to community, sustainability, and inclusivity.*

- See [CNCF announcement](https://www.cncf.io/announcement/2020/04/30/cloud-native-computing-foundation-announces-helm-graduation/)
  and [Helm announcement](https://helm.sh/blog/celebrating-helms-cncf-graduation/)

- In other words: Helm is here to stay

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

- If you see references to `tiller` in a tutorial, documentation... that doc is obsolete!

---

class: extra-details

## What was the problem with `tiller`?

- With Helm 3:

  - the `helm` CLI communicates directly with the Kubernetes API

  - it creates resources (deployments, services...) with our credentials

- With Helm 2:

  - the `helm` CLI communicates with `tiller`, telling `tiller` what to do

  - `tiller` then communicates with the Kubernetes API, using its own credentials

- This indirect model caused significant permissions headaches

- It also made it more complicated to embed Helm in other tools

---

## Helm 3 vs Helm 4

- [Server-Side Apply][k8s-ssa] support

  (more efficient updates; avoids conflicts when there are concurrent updates)

- New plugin architecture

  - WASM support

  - distinct plugin types (CLI, postrenderer, getter)

- More reliable "wait for resource to be up" with [kstatus]

  (use well-known condition names to track resource status; e.g. `Current` or `Ready`)

- Better OCI support (e.g. digests pinning)

- And much more!

[k8s-ssa]: https://kubernetes.io/docs/reference/using-api/server-side-apply/
[kstatus]: https://github.com/kubernetes-sigs/cli-utils/tree/master/pkg/kstatus

---

## Installing Helm

- If the `helm` CLI is not installed in your environment, install it

.lab[

- Check if `helm` is installed:
  ```bash
  helm
  ```

- If it's not installed, run the following command:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 \
  | bash
  ```

- Or download the latest release [from GitHub][helm-releases]

]

[helm-releases]: https://github.com/helm/helm/releases

---

## Charts

- Helm works with *charts*

  (a chart is a collection of files)

- A chart can exist:

  - as plain local files (ideal for development, rapid iteration)

  - as a bundle on an online *repository* (ideal for distribution)

---

## Repositories

- A *repository* (or repo in short) is a collection of charts

- Helm supports HTTP and OCI repositories

- HTTP repositories (legacy):

  - static HTTP servers with a special index file (see `helm repo index`)

  - charts are tarballs

- OCI repositories (newer):

  - same format and protocol as container images

  - no special index file (updates are easier)

---

## How to find charts

- Go to the [Artifact Hub](https://artifacthub.io/packages/search?kind=0) (https://artifacthub.io)

- Or use `helm search hub ...` from the CLI

- Let's try to find a Helm chart for something called "OWASP Juice Shop"!

  (it is a famous demo app used in security challenges)

---

## Finding charts from the CLI

- We can use `helm search hub <keyword>`

.lab[

- Look for the OWASP Juice Shop app:
  ```bash
  helm search hub owasp juice
  ```

- Since the URLs are truncated, try with the YAML output:
  ```bash
  helm search hub owasp juice -o yaml
  ```

]

---

## Finding charts on the web

- We can also use the Artifact Hub search feature

.lab[

- Go to https://artifacthub.io/

- In the search box on top, enter "owasp juice"

- Click on the "juice-shop" result (not "multi-juicer" or "juicy-ctf")

]

---

## Installing the chart

- Click on the "Install" button, it will show instructions

- If the page wasn't available... Use the command below!


.lab[

- Install the chart:
  ```bash
  helm install my-juice-shop oci://ghcr.io/securecodebox/helm/juice-shop
  ```

]

---

## Charts and releases

- "Installing a chart" means creating a *release*

- In the previous example, the release was named "my-juice-shop"

- We can also use `--generate-name` to ask Helm to generate a name for us

.lab[

- List the releases:
  ```bash
  helm list
  ```

- Check that we have a `my-juice-shop-...` Pod up and running:
  ```bash
  kubectl get pods
  ```

]

---

## Viewing resources of a release

- This specific chart labels all its resources with a `release` label

- We can use a selector to see these resources

.lab[

- List all the resources created by this release:
  ```bash
  kubectl get all --selector=app.kubernetes.io/instance=my-juice-shop
  ```

]

Note: this label wasn't added automatically by Helm.
<br/>
It is defined in that chart. In other words, not all charts will provide this label.

---

## Configuring a release

- By default, `juice-shop` creates a service of type `ClusterIP`

- We would like to change that to a `NodePort`

- We could use `kubectl edit service my-juice-shop`, but ...

  ... our changes would get overwritten next time we update that chart!

- Instead, we are going to *set a value*

- Values are parameters that the chart can use to change its behavior

- Values have default values

- Each chart is free to define its own values and their defaults

---

## Checking possible values

- We can inspect a chart with `helm show` or `helm inspect`

.lab[

- Look at the README for the app:
  ```bash
  helm show readme oci://ghcr.io/securecodebox/helm/juice-shop
  ```

- Look at the values and their defaults:
  ```bash
  helm show values oci://ghcr.io/securecodebox/helm/juice-shop
  ```

]

The `values` may or may not have useful comments.

The `readme` may or may not have (accurate) explanations for the values.

(If we're unlucky, there won't be any indication about how to use the values!)

---

## Setting values

- Values can be set when installing a chart, or when upgrading it

- We are going to update `my-juice-shop` to change the type of the service

.lab[

- Update `my-juice-shop`:
  ```bash
  helm upgrade my-juice-shop oci://ghcr.io/securecodebox/helm/juice-shop \
       --set service.type=NodePort
  ```

]

---

## Gotchas

- We need to specify the chart name again

  (even if we just want to update some values)

- We can set multiple values (with multiple `--set` options)

- We can also set multiple values with `-f`/`--values` and pass a YAML file

  (very useful when there are *many* values, or complex nested values)

- If we set at least one value, it will reset all other values to their defaults

  (unless we pass `--reuse-values`)

---

## Connecting to the Juice Shop

- Let's check the app that we just installed

.lab[

- Check the node port allocated to the service:
  ```bash
  kubectl get service my-juice-shop
  PORT=$(kubectl get service my-juice-shop -o jsonpath={..nodePort})
  ```

- Connect to it:
  ```bash
  curl localhost:$PORT/
  ```

]

---

## Installing from HTTP repos

- Standard approach:
  ```bash
  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
  helm install metrics-server metrics-server/metrics-server --version 3.14.0
  ```

  (Note: the repo name is arbitrary; it doesn't have to match `metrics-server`.)

- One-liner approach:
  ```bash
  helm install metrics-server metrics-server/metrics-server --version 3.14.0 \
       --repo https://kubernetes-sigs.github.io/metrics-server/
  ```

???

:EN:- Helm concepts
:EN:- Installing software with Helm
:EN:- Finding charts on the Artifact Hub

:FR:- Fonctionnement général de Helm
:FR:- Installer des composants via Helm
:FR:- Trouver des *charts* sur *Artifact Hub*

:T: Getting started with Helm and its concepts

:Q: Which comparison is the most adequate?
:A: Helm is a firewall, charts are access lists
:A: ✔️Helm is a package manager, charts are packages
:A: Helm is an artefact repository, charts are artefacts
:A: Helm is a CI/CD platform, charts are CI/CD pipelines

:Q: What's required to distribute a Helm chart?
:A: A Helm commercial license
:A: A Docker registry
:A: An account on the Helm Hub
:A: ✔️An HTTP server
