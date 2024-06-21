# Git-based workflows (GitOps)

- Deploying with `kubectl` has downsides:

  - we don't know *who* deployed *what* and *when*

  - there is no audit trail (except the API server logs)

  - there is no easy way to undo most operations

  - there is no review/approval process (like for code reviews)

- We have all these things for *code*, though

- Can we manage cluster state like we manage our source code?

---

## Reminder: Kubernetes is *declarative*

- All we do is create/change resources

- These resources have a perfect YAML representation

- All we do is manipulate these YAML representations

  (`kubectl run` generates a YAML file that gets applied)

- We can store these YAML representations in a code repository

- We can version that code repository and maintain it with best practices

  - define which branch(es) can go to qa/staging/production

  - control who can push to which branches

  - have formal review processes, pull requests, test gates...

---

## Enabling git-based workflows

- There are a many tools out there to help us do that; with different approaches

- "Git host centric" approach: GitHub Actions, GitLab...

  *the workflows/action are directly initiated by the git platform*

- "Kubernetes cluster centric" approach: [ArgoCD], [FluxCD]..

  *controllers run on our clusters and trigger on repo updates*

- This is not an exhaustive list (see also: Jenkins)

- We're going to talk mostly about "Kubernetes cluster centric" approaches here

[ArgoCD]: https://argoproj.github.io/cd/
[Flux]: https://fluxcd.io/

---

## The road to production

In no specific order, we need to at least:

- Choose a tool

- Choose a cluster / app / namespace layout
  <br/>
  (one cluster per app, different clusters for prod/staging...)

- Choose a repository layout
  <br/>
  (different repositories, directories, branches per app, env, cluster...)

- Choose an installation / bootstrap method

- Choose how new apps / environments / versions will be deployed

- Choose how new images will be built

---

## Flux vs ArgoCD (1/2)

- Flux:

  - fancy setup with an (optional) dedicated `flux bootstrap` command
    <br/>
    (with support for specific git providers, repo creation...)

  - deploying an app requires multiple CRDs
    <br/>
    (Kustomization, HelmRelease, GitRepository...)

  - supports Helm charts, Kustomize, raw YAML

- ArgoCD:

  - simple setup (just apply YAMLs / install Helm chart)

  - fewer CRDs (basic workflow can be implement with a single "Application" resource)

  - supports Helm charts, Jsonnet, Kustomize, raw YAML, and arbitrary plugins

---

## Flux vs ArgoCD (2/2)

- Flux:

  - sync interval is configurable per app
  - no web UI out of the box
  - CLI relies on Kubernetes API access
  - CLI can easily generate custom resource manifests (with `--export`)
  - self-hosted (flux controllers are managed by flux itself by default)
  - one flux instance manages a single cluster

- ArgoCD:

  - sync interval is configured globally
  - comes with a web UI
  - CLI can use Kubernetes API or separate API and authentication system
  - one ArgoCD instance can manage multiple clusters

---

## Cluster, app, namespace layout

- One cluster per app, different namespaces for environments?

- One cluster per environment, different namespaces for apps?

- Everything on a single cluster? One cluster per combination?

- Something in between:

  - prod cluster, database cluster, dev/staging/etc cluster

  - prod+db cluster per app, shared dev/staging/etc cluster

- And more!

Note: this decision isn't really tied to GitOps!

---

## Repository layout

So many different possibilities!

- Source repos

- Cluster/infra repos/branches/directories

- "Deployment" repos (with manifests, charts)

- Different repos/branches/directories for environments

🤔 How to decide?

---

## Permissions

- Different teams/companies = different repos

  - separate platform team → separate "infra" vs "apps" repos

  - teams working on different apps → different repos per app

- Branches can be "protected" (`production`, `main`...)

  (don't need separate repos for separate environments)

- Directories will typically have the same permissions

- Managing directories is easier than branches

- But branches are more "powerful" (cherrypicking, rebasing...)

---

## Resource hierarchy

- Git-based deployments are managed by Kubernetes resources

  (e.g. Kustomization, HelmRelease with Flux; Application with ArgoCD)

- We will call these resources "GitOps resources"

- These resources need to be managed like any other Kubernetes resource

  (YAML manifests, Kustomizations, Helm charts)

- They can be managed with Git workflows too!

---

## Cluster / infra management

- How do we provision clusters?

- Manual "one-shot" provisioning (CLI, web UI...)

- Automation with Terraform, Ansible...

- Kubernetes-driven systems (Crossplane, CAPI)

- Infrastructure can also be managed with GitOps

---

## Example 1

- Managed with YAML/Charts:

  - core components (CNI, CSI, Ingress, logging, monitoring...)

  - GitOps controllers

  - critical application foundations (database operator, databases)

  - GitOps manifests

- Managed with GitOps:

  - applications

  - staging databases

---

## Example 2

- Managed with YAML/Charts:

  - essential components (CNI, CoreDNS)

  - initial installation of GitOps controllers

- Managed with GitOps:

  - upgrades of GitOps controllers

  - core components (CSI, Ingress, logging, monitoring...)

  - operators, databases

  - more GitOps manifests for applications!

---

## Concrete example

- Source code repository (not shown here)

- Infrastructure repository (shown below), single branch

```
@@INCLUDE[slides/k8s/gitopstree.txt]
```

???

:EN:- GitOps
:FR:- GitOps
