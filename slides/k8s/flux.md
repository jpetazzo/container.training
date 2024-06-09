# FluxCD

- We're going to implement a basic GitOps workflow with Flux

- Pushing to `main` will automatically deploy to the clusters

- There will be two clusters (`dev` and `prod`)

- The two clusters will have similar (but slightly different) workloads

---

## Repository structure

This is (approximately) what we're going to do:

```
@@INCLUDE[slides/k8s/gitopstree.txt]
```

---

## Getting ready

- Let's make sure we have two clusters

- It's OK to use local clusters (kind, minikube...)

- We might run into resource limits, though

  (pay attention to `Pending` pods!)

- We need to install the Flux CLI ([packages], [binaries])

- **Highly recommended:** set up CLI completion!

- Of course we'll need a Git service, too

  (we're going to use GitHub here)

[packages]: https://fluxcd.io/flux/get-started/
[binaries]: https://github.com/fluxcd/flux2/releases

---

## GitHub setup

- Generate a GitHub token:

  https://github.com/settings/tokens/new

- Give it "repo" access

- This token will be used by the `flux bootstrap github` command later

- It will create a repository and configure it (SSH key...)

- The token can be revoked afterwards

---

## Flux bootstrap

.lab[

- Let's set a few variables for convenience, and create our repository:
  ```bash
    export GITHUB_TOKEN=...
    export GITHUB_USER=changeme
    export GITHUB_REPO=alsochangeme
    export FLUX_CLUSTER=dev

    flux bootstrap github \
      --owner=$GITHUB_USER \
      --repository=$GITHUB_REPO \
      --branch=main \
      --path=./clusters/$FLUX_CLUSTER \
      --personal --public
  ```

]

Problems? check next slide!

---

## What could go wrong?

- `flux bootstrap` will create or update the repository on GitHub

- Then it will install Flux controllers to our cluster

- Then it waits for these controllers to be up and running and ready

- Check pod status in `flux-system`

- If pods are `Pending`, check that you have enough resources on your cluster

- For testing purposes, it should be fine to lower or remove Flux `requests`!

  (but don't do that in production!)

- If anything goes wrong, don't worry, we can just re-run the bootstrap

---

class: extra-details

## Idempotence

- It's OK to run that same `flux bootstrap` command multiple times!

- If the repository already exists, it will re-use it

  (it won't destroy or empty it)

- If the path `./clusters/$FLUX_CLUSTER` already exists, it will update it

- It's totally fine to re-run `flux bootstrap` if something fails

- It's totally fine to run it multiple times on different clusters

- Or even to run it multiple times for the *same* cluster

  (to reinstall Flux on that cluster after a cluster wipe / reinstall)

---

## What do we get?

- Let's look at what `flux bootstrap` installed on the cluster

.lab[

- Look inside the `flux-system` namespace:
  ```bash
  kubectl get all --namespace flux-system
  ```

- Look at `kustomizations` custom resources:
  ```bash
  kubectl get kustomizations --all-namespaces
  ```

- See what the `flux` CLI tells us:
  ```bash
  flux get all
  ```

]

---

## Deploying with GitOps

- We'll need to add/edit files on the repository

- We can do it by using `git clone`, local edits, `git commit`, `git push`

- Or by editing online on the GitHub website

.lab[

- Create a manifest; for instance `clusters/dev/flux-system/blue.yaml`

- Add that manifest to `cluseters/dev/kustomization.yaml`

- Commit and push both changes to the repository

]

---

## Waiting for reconciliation

- Compare the git hash that we pushed and the one show with `kubectl get `

- Option 1: wait for Flux to pick up the changes in the repository

  (the default interval for git repositories is 1 minute, so that's fast)

- Option 2: use `flux reconcile source git flux-system`

  (this puts an annotation on the appropriate resource, triggering an immediate check)

---

## Checking progress

- `flux logs`

- `kubectl get gitrepositories --all-namespaces`

- `kubectl get kustomizations --all-namespaces`

---

## Did it work?

--

- No!

--

- Why?

--

- We need to indicate the namespace where the app should be deployed

- Either in the YAML manifests

- Or in the `kustomization` custom resource

  (using field `spec.targetNamespace`)

- Add the namespace to the manifest and try again!

---

## Adding an app in a reusable way

- Let's see a technique to add a whole app

  (with multiple resource manifets)

- We want that to be reusable

  (i.e. easy to add on multiple clusters with minimal changes)

---

## The plan

- Add the app manifests in a directory

  (e.g.: `apps/myappname/manifests`)

- Create a kustomization manifest for the app and its namespace

  (e.g.: `apps/myappname/flux.yaml`)

- The kustomization manifest will refer to the app manifest

- Add the kustomization manifest to the top-level `flux-system` kustomization

---

## Creating the manifests

- All commands below should be executed at the root of the repository

.lab[

- Put application manifests in their directory:
  ```bash
  mkdir -p apps/dockercoins
  cp ~/container.training/k8s/dockercoins.yaml apps/dockercoins/
  ```

- Create kustomization manifest:
  ```bash
    flux create kustomization dockercoins \
      --source=GitRepository/flux-system \
      --path=./apps/dockercoins/manifests/ \
      --target-namespace=dockercoins \
      --prune=true --export > apps/dockercoins/flux.yaml
  ```

]

---

## Creating the target namespace

- When deploying *helm releases*, it is possible to automatically create the namespace

- When deploying *kustomizations*, we need to create it explicitly

- Let's put the namespace with the kustomization manifest

  (so that the whole app can be mediated through a single manifest)

.lab[

- Add the target namespace to the kustomization manifest:
  ```bash
    echo "---
    kind: Namespace
    apiVersion: v1
    metadata:
      name: dockercoins" >> apps/dockercoins/flux.yaml
  ```

]

---

## Linking the kustomization manifest

- Edit `clusters/dev/flux-system/kustomization.yaml`

- Add a line to reference the kustomization manifest that we created:
  ```yaml
  - ../../../apps/dockercoins/flux.yaml
  ```

- `git add` our manifests, `git commit`, `git push`

  (check with `git status` that we haven't forgotten anything!)

- `flux reconcile` or wait for the changes to be picked up

---

## Installing with Helm

- We're going to see two different workflows:

  - installing a third-party chart
    <br/>
    (e.g. something we found on the Artifact Hub)

  - installing one of our own charts
    <br/>
    (e.g. a chart with authored ourselves)

- The procedures are very similar

---

## Installing from a public Helm repository

- Let's install [kube-prometheus-stack][kps]

.lab[

- Create the Flux manifests:
  ```bash
  mkdir -p apps/kube-prometheus-stack
  flux create source helm kube-prometheus-stack \
       --url=https://prometheus-community.github.io/helm-charts \
       --export >> apps/kube-prometheus-stack/flux.yaml
  flux create helmrelease kube-prometheus-stack \
       --source=HelmRepository/kube-prometheus-stack \
       --chart=kube-prometheus-stack --release-name=kube-prometheus-stack \
       --target-namespace=kube-prometheus-stack --create-target-namespace \
       --export >> apps/kube-prometheus-stack/flux.yaml
  ```

]

[kps]: https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack

---

## Enable the app

- Just like before, link the manifest from the top-level kustomization

  (`flux-system` in namespace `flux-system`)

- `git add` / `git commit` / `git push`

- We should now have a Prometheus+Grafana observability stack!

---

## Installing from a Helm chart in a git repo

- In this example, the chart will be in the same repo

- In the real world, it will typically be in a different repo!

.lab[

- Generate a basic Helm chart:
  ```bash
  mkdir -p charts
  helm create charts/myapp
  ```

]

(This generates a chart which installs NGINX. A lot of things can be customized, though.)

---

## Creating the Flux manifests

- The invocation is very similar to our first example

.lab[

- Generate the Flux manifest for the Helm release:
  ```bash
  mkdir apps/myapp
  flux create helmrelease myapp \
       --source=GitRepository/flux-system \
       --chart=charts/myapp \
       --target-namespace=myapp --create-target-namespace \
       --export > apps/myapp/flux.yaml
  ```

- Add that manifest to the top-level kustomization

- `git add` / `git commit` / `git push` the chart, manifest, and kustomization

]

---

## Passing values

- We can also configure our Helm releases with values

- Using an existing `myvalues.yaml` file:

  `flux create helmrelease ... --values=myvalues.yaml`

- Referencing an existing ConfigMap or Secret with a `values.yaml` key:

  `flux create helmrelease ... --values-from=ConfigMap/myapp`

---

## Gotchas

- When creating a HelmRelease using a chart stored in a git repository, you must:

  - either bump the chart version (in `Chart.yaml`) after each change,

  - or set `spec.chart.spec.reconcileStrategy` to `Revision`

- Why?

- Flux installs helm releases using packaged artifacts

- Artifacts are updated only when the Helm chart version changes

- Unless `reoncileStrategy` is set to `Revision` (instead of the default `ChartVersion`)

---

## More gotchas

- There is a bug in Flux that prevents using identical subcharts with aliases

- See [fluxcd/flux2#2505][flux2505] for details

[flux2505]: https://github.com/fluxcd/flux2/discussions/2505

---

## Things that we didn't talk about...

- Bucket sources

- Image automation controller

- Image reflector controller

- And more!

???

:EN:- Implementing gitops with Flux
:FR:- Workflow gitops avec Flux

<!--

helm upgrade --install --repo https://dl.gitea.io/charts --namespace gitea --create-namespace gitea gitea \
  --set persistence.enabled=false \
  --set redis-cluster.enabled=false \
  --set postgresql-ha.enabled=false \
  --set postgresql.enabled=true \
  --set gitea.config.session.PROVIDER=db \
  --set gitea.config.cache.ADAPTER=memory \
  #

### Boostrap Flux controllers

```bash
mkdir -p flux/flux-system/gotk-components.yaml
flux install --export > flux/flux-system/gotk-components.yaml
kubectl apply -f flux/flux-system/gotk-components.yaml
```

### Bootstrap GitRepository/Kustomization

```bash
export REPO_URL="<gitlab_url>" DEPLOY_USERNAME="<username>"
read -s DEPLOY_TOKEN
flux create secret git flux-system --url="${REPO_URL}" --username="${DEPLOY_USERNAME}" --password="${DEPLOY_TOKEN}"
flux create source git flux-system --url=$REPO_URL --branch=main --secret-ref flux-system --ignore-paths='/*,!/flux' --export > flux/flux-system/gotk-sync.yaml
flux create kustomization flux-system --source=GitRepository/flux-system --path="./flux" --prune=true --export >> flux/flux-system/gotk-sync.yaml

git add flux/ && git commit -m 'feat: Setup Flux' flux/ && git push
kubectl apply -f flux/flux-system/gotk-sync.yaml
```

-->

