# GitOps with ArgoCD

- Resources in our Kubernetes cluster can be described in YAML files

- These YAML files can and should be stored in source control - specifically - Git

- YAML manifests from Git can then be used to continuously update our cluster configuraition

- When this process is automated - it is now called "GitOps"

- The term was coined by Alexis Richardson of Weaveworks.

- Many tools exist for GitOps automation

- ArgoCD is one of the most popular ones due to its slick WebUI

---

## ArgoCD overview

![ArgoCD Logo](images/argocdlogo.png)
- We put our Kubernetes resources as YAML files (or Helm charts) in a git repository

- ArgoCD polls that repository regularly 

- The resources described in git are created/updated automatically

- Changes are made by updating the code in the repository

---
## ArgoCD - the Core Concepts

- ArgoCD manages **Applications** by **syncing** their **live state** with their **target state**

- **Application**: A group of Kubernetes resources as defined by a manifest. ArgoCD applies a Custom Resource Definition (CRD) to manage these.

- **Application source type**: Which **Tool** is used to build the application. (e.g: Helm. Kustomize, Jsonnette)

- **Target state**: The desired state of an **application**, as represented by files in a Git repository.
- **Live state**:  The live state of that application. What pods etc are deployed, etc.

- **Sync status**: Whether or not the live state matches the target state. Is the deployed application the same as Git says it should be?

- **Sync**: The process of making an application move to its target state. E.g. by applying changes to a Kubernetes cluster.

---

## Setting up ArgoCD

- We have a YAML file that installs core ArgoCD components 

- Apply the yaml:

```bash
kubectl create namespace argocd
kubectl apply ~/container.training/k8s/argocd.yaml
```

- This will create a new namespace, argocd, where Argo CD services and application resources will live.

---

## Installing the ArgoCD CLI

- ArgoCD features both a WebUI and a CLI

- CLI can be used for automation and some of the configuration not currently available in the WebUI

- Download the CLI:

.exercise[
```bash
VERSION=v2.2.1
curl -sSL -o /usr/local/bin/argocd \ 
    https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```
]
---
## Logging in with the ArgoCD CLI

Verify we can login to ArgoCD via CLI:

```bash
argocd login --core
```

You should see "Context 'kubernetes' updated"



- Note: argocd cli can talk to ArgoCD API server or to Kubernetes API

In the `--core` mode it talks directly to Kubernetes

- So ArgoCD  has an API server! But what else is there?

- Let's Look at ArgoCD Architecture!

---

class: pic
## ArgoCD Architecture

![ArgoCD Architecture](images/argocd_architecture.png)

---
## ArgoCD API Server

The API server is a gRPC/REST server which exposes the API consumed by the Web UI, CLI, and CI/CD systems. It has the following responsibilities:

- application management and status reporting

- invoking of application operations (e.g. sync, rollback, user-defined actions)

- repository and cluster credential management (stored as K8s secrets)

- authentication and auth delegation to external identity providers

- RBAC enforcement

- listener/forwarder for Git webhook events
---
## ArgoCD Repository Server

The repository server is an internal service which maintains a local cache of the Git repository holding the application manifests. It is responsible for generating and returning the Kubernetes manifests when provided the following inputs:

- repository URL

- revision (commit, tag, branch)

- application path

- template specific settings: parameters, ksonnet environments, helm values.yaml

---

## ArgoCD Application Controller

The application controller is a Kubernetes controller which continuously monitors running applications and compares the current, live state against the desired target state (as specified in the repo). 

It detects *OutOfSync* application state and optionally takes corrective action. 

It is responsible for invoking any user-defined hooks for lifecycle events (*PreSync, Sync, PostSync*)

---
## Preparing a repository for ArgoCD

- We need a repository with Kubernetes YAML files

- Let's use **kubercoins**: https://github.com/otomato-gh/kubercoins

- Fork it to your GitHub account

- Create a new branch in your fork; e.g. `prod`

  (e.g. by adding a line in the README through the GitHub web UI)

- This is the branch that we are going to use for deployment

---
## Start Managing an Application

- An Application can be added to ArgoCD (and consequently - to our cluster) vi UI or CLI

- Adding an Application via CLI:

.exercise[
```bash
argocd app create kubercoins \ 
--repo https://github.com/<your_user>/kubercoins.git \
--path . --revision prod \
--dest-server https://kubernetes.default.svc \
--dest-namespace kubercoins-prod
```
Check what we did:
```bash
argocd app list
```
The app is there and it is `OutOfSync`!
]
---

## Syncing the Application vi CLI

- Let's sync kubercoins into our cluster

.exercise[
```bash
  argocd app sync kubercoins
```
]
--

We should recieve a failure:

`Operation has completed with phase: Failed`

And the culprit is:

`Message: one or more objects failed to apply, reason: namespaces "kubercoins-prod" not found`

We need to create a namespace!

---

## Sync Options

- Syncing is only trivial in theory

- There are a lot of edge cases

- Hence ArgoCD supports "Sync Options"

- One of them is "CreateNamespace"

- Some [others](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/) are: `FailOnSharedResource`, `PruneLast`, `PrunePropagationPolicy`

---
## Let's edit the sync options of our app
.exercise[
```bash
argocd app edit kubercoins
```
Add this to the YAML opened in the console (root level):
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
```
Now retry sync:
```bash
argocd app sync kubercoins
```
]

Looks better now!

---

## Managing Applications via the Web UI

- ArgoCD is popular in large part due to it's browser-based UI

- Let's see how to manage Applications in the UI

- ArgoCD web dashboard should be available on your lab machine's port 30006

- Alternatively we can run it on port 8080 by executing: `argocd admin dasboard`

.exercise[
  Open the ArgoCD Web UI
]

---

## Let's add a Staging environment for our Application

* Create a branch named "stage" in your **kubercoins** fork
* Back in ArgoCD UI - click "New application"

| Field | Value |
|-------|-------|
| Application name: | `kubercoins-stg` |
| Project: | `default` |
| Sync policy: | `Manual` |
| Repository: | `https://github.com/${username}/kubercoins` |
| Revision: | `stage` |
| Path: | `.` |
| Cluster: | `https://kubernetes.default.svc` |
| Namespace: | `kubercoins-stg` |
  
---
## Sync Your Application from the UI

* Click "Sync".

* Click "Synchronize" in the Sliding panel.

* Watch app status become Healthy and Synced

---
## Making Changes

- Let's see what happens when we change our app

- Change the image tag in worker-deployment.yaml to v0.3 (on the `stage` branch)

- Line 18: 
`      - image: dockercoins/worker:v0.3`

- In a few moments the `kubercoins-stg` application will show OutOfSync in both the UI and when running `argocd app list`

.exercise[
  Check the application sync status:
  ```bash
  argocd app list
  ```
]

---

## Automating the Sync for True CD

- Syncing manually for every change isn't really doing CD

- Argo allows us to automate the sync process

- Note that this requires much more rigorous production testing and observability - in order to make sure that the changes we do in Git don't crash our app and the cluster as a whole.

- Argo project provides a complementary Progressive Delivery controller - Argo Rollouts - that helps us make sure all our deployment roll out safely

- But today we will just turn on automated sync for the staging namespace

---

##  Enable AutoSync

- In Web UI - go to Applications -> kubercoins-stg -> App Details

- Under Sync Policy - click on "ENABLE AUTO-SYNC"

- The application goes into sync and the `worker` deployment gets stuck in `progressing`

.exercise[
  Check the applicationn resource health:
  ```bash
  argocd app get kubercoins-stg -ojson | \ 
  jq ".status.resources[]| {name: .name} + .health"
  ```
]

Worker deployment will show "Progressing" for a while until it's marked as "Degraded"

Makes sense - there is no `v0.3` image for worker!

---

## Rolling Back a Bad Deployment

- Sometimes we deploy a bad version.

- Or a non-existent one (as we just did with v0.3)

- Depending on our rolling update strategy this can leave our application in a partially degraded state.

- Let's see how to roll back a degraded sync.

---

## Emergency Rollback

- The purist way of rolling back would be doing it with GitOps (see next slide)

- But sometimes we don't have time to go through the pipeline. We just need to get back to the previous version.

- That's when we apply "emergency rollback"

.exercise[

* On application details page - click "History And Rollback"
* Click "..." button in the last row
* Click "Rollback" 
  * Note that we'll have to disable auto-sync for that
* Click "Ok" in the modal panel
]
--

After a while the application goes back to healthy but OutOfSync

---
## GitOps Rollback

- The correct way to roll back is rolling back the code in source control

.exercise[
```bash
  git checkout stage
  git revert HEAD
  git push origin stage
```
]
--

- Click on 'Refresh' on the application box in the UI

- Watch the application go back to "Synced"

---

## Working with Helm

- ArgoCD supports different Kubernetes deployment tools: Kustomize, Jsonnnet, Ksonnet and of course **Helm**

- Let's see what features ArgoCD offers for working with Helm Charts

- In our `kubercoins` repo there's a branch called `helm`

- It provides a generic helm chart found in the `generic-service` directory

- And service-specific `values` files in the `values` directory. 

- We'll create an application for each of our services reusing the same helm chart.

- We have an ArgoCD Application resource manifest ready at `~/container.training/k8s/argocd_app.yaml`


---
##  ArgoCD Application Resource

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kc-worker
spec:
  destination:
    namespace: helmcoins
    server: 'https://kubernetes.default.svc'
  source:
    path: generic-service
    repoURL: 'https://github.com/antweiss/kubercoins.git'
    targetRevision: helm
    helm:
      valueFiles:
        - values.yaml
        - ../values/worker.yaml
...
  ```

---

## Create an Application for each Microservice

.exercise[

```bash
kubectl apply -f ~/container.training/k8s/argocd_app.yaml
argocd app sync worker
```


Change the ~/container.training/k8s/argocd_app.yaml to deploy `rng`, `hasher`, `redis` and `webui`. 

Apply the application resource for each.

]