# Kubernetes in production — <br/>an end-to-end example

- Previous training modules focused on individual topics

  (e.g. RBAC, network policies, CRDs, Helm…)

- We will now show how to put everything together to deploy apps in production

  (dealing with typical challenges like: multiple apps, multiple teams, multiple clusters…)

- Our first challenge will be to pick and choose which components to use

  (among the vast [Cloud Native Landscape](https://landscape.cncf.io/))

- We'll start with a basic Kubernetes cluster (on cloud or on premises)

- We'll and enhance it by adding features one at a time

---

## The cast

There are 3 teams in our company:

- **_⚙️OPS_** is the platform engineering team

  - they're responsible for building and configuring Kubernetes clusters

- the **_🎸ROCKY_** team develops and manages the **_🎸ROCKY_** app

  - that app manages a collection of _rock & pop_ albums

- the **_🎬MOVY_** team develops and manages the **_🎬MOVY_** app

  - that app manages a collection of _movie soundtrack_ albums

Both apps are deployed with plain YAML manifests

---

## Code and team organization

- **_🎸ROCKY_** and **_🎬MOVY_** reside in separate git repositories

- Each team can write code, build package, and deploy their applications:

  - independently
    <br/>(= without having to worry about what's happening in the other repo)

  - autonomously
    <br/>(= without having to synchronize or obtain privileges from another team)

---

## Cluster organization

The **_⚙️OPS_** team manages 2 Kubernetes clusters:

- **_☁️CLOUDY_**: managed cluster from a public cloud provider

- **_🤘METAL_**: custom-built cluster installed on bare Linux servers

Let's see the differences between these clusters.

---

## **_☁️CLOUDY_** cluster

- Managed cluster from a public cloud provider ("Kubernetes-as-a-Service")

- HA control plane deployed and managed by the cloud provider

- Two worker nodes (potentially with cluster autoscaling)

- Usually comes pre-installed with some basic features

  (e.g. metrics-server, CNI, CSI, sometimes an ingress controller)

- Requires extra components to be production-ready

  (e.g. Flux or other gitops pipeline, observability…)

- Example: [Scaleway Kapsule][kapsule] (but many other KaaS options are available)

[kapsule]: https://www.scaleway.com/en/kubernetes-kapsule/

---

## **_🤘METAL_** cluster

- Custom-built cluster installed on bare Linux servers

- HA control plane deployed and managed by the **_⚙️OPS_** team

- 3 nodes

  - in our example, the nodes will run both the control plane and our apps

  - it is more typical to use dedicated control plane nodes
    <br/>(example: 3 control plane nodes + at least 3 worker nodes)

- Comes with even less pre-installed components than **_☁️CLOUDY_**

  (requiring more work from our **_⚙️OPS_** team)

- Example: we'll use [k0s] (but many other distros are available)

[k0s]: https://k0sproject.io/

---

## **_⚗️TEST_** and **_🏭PROD_** 

- The **_⚙️OPS_** team creates 2 environments for each dev team

  (**_⚗️TEST_** and **_🏭PROD_**)

- These environments exist on both clusters

  (meaning 2 apps × 2 clusters × 2 envs = 8 envs total)

- The setup for each env and cluster should follow DRY principles

  (to ensure configurations are consistent and minimize maintenance)
  
- Each cluster and each env has its own lifecycle

  (= it should be possible to deploy, add an extra components/feature…
  <br/>on one env without impacting the other)

---

### Multi-tenancy

Both **_🎸ROCKY_** and **_🎬MOVY_** teams should use **dedicated _"tenants"_** on each cluster/env

- the **_🎸ROCKY_** team should be able to deploy, upgrade and configure its app within its dedicated **namespace** without anybody else involved

- and the same for **_🎬MOVY_**

- neither team's deployments might interfere with the other, maintaining a clean and conflict-free environment

---

## Application overview

- Both dev teams are working on an app to manage music albums

- This app is mostly based on a `Spring` framework demo called spring-music

- This lab uses a dedicated fork [container.training-spring-music](https://github.com/Musk8teers/container.training-spring-music):
  -  with 2 branches dedicated to the **_🎸ROCKY_** and **_🎬MOVY_** teams

- The app architecture consists of 2 tiers:
  - a `Java/Spring` Web app
  - a `PostgreSQL` database

---

### 📂 specific file: application.yaml

This is where we configure the application to connect to the `PostgreSQL` database.

.lab[

🔍 Location: [/src/main/resources/application.yml](https://github.com/Musk8teers/container.training-spring-music/blob/main/src/main/resources/application.yml)

]

`PROFILE=postgres` env var is set in [docker-compose.yaml](https://github.com/Musk8teers/container.training-spring-music/blob/main/docker-compose.yml) file, for example…  

---

### 📂 specific file: AlbumRepositoryPopulator.java


This is where the album collection is initially loaded from the file [`album.json`](https://github.com/Musk8teers/container.training-spring-music/blob/main/src/main/resources/albums.json)

.lab[

🔍 Location: [`/src/main/java/org/cloudfoundry/samples/music/repositories/AlbumRepositoryPopulator.java`](https://github.com/Musk8teers/container.training-spring-music/blob/main/src/main/java/org/cloudfoundry/samples/music/repositories/AlbumRepositoryPopulator.java)

]

---

## 🚚 How to deploy?

The **_⚙️OPS_** team offers 2 deployment strategies that dev teams can use autonomously:

- Both **_🎸ROCKY_** and **_🎬MOVY_** use a `Flux` _GitOps_ workflow based on regular Kubernetes `YAML` resources

- Another `Flux` _GitOps_ workflow based on `Helm` charts might be proposed as well

---

## 🍱 What features?

<!-- TODO: complete this slide when all the modules are there -->
The **_⚙️OPS_** team aims to provide clusters offering the following features to its users:

- a network stack with efficient workload isolation

- ingress and load-balancing capabilites

- an enterprise-grade monitoring solution for real-time insights et log browsing

- automated policy rule enforcement to control Kubernetes resources requested by dev teams

- a semi-managed PostgreSQL including automated failover and backups

- automated generation of HTTPs certificates to expose the applications

---

## 🌰 In a nutshell

- 3 teams: **_⚙️OPS_**, **_🎸ROCKY_**, **_🎬MOVY_**

- 2 clusters: **_☁️CLOUDY_**, **_🤘METAL_**

- 2 envs per cluster and per dev team: **_⚗️TEST_**, **_🏭PROD_**

- 2 Web apps Java/Spring + PostgreSQL: one for pop and rock albums, another for movie soundtrack albums

- 2 deployment strategies: regular `YAML` resources + `Kustomize`, `Helm` charts


> 💻 `Flux` is used both
> - to operate the clusters
> - and to manage the _GitOps_ deployment workflows

---

### What our scenario might look like…

<pre class="mermaid">
%%{init:
    {
      "theme": "default",
      "gitGraph": {
        "mainBranchName": "OPS",
        "mainBranchOrder": 0
      }
    }
}%%
gitGraph
    commit id:"0" tag:"start"
    branch ROCKY order:4
    branch MOVY order:5
    branch YouRHere order:6

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

    commit id:'Flux install on CLOUDY cluster' type: HIGHLIGHT
    commit id:'Prometheus + Grafana config.'
    commit id:'Prometheus + Grafana install' type: HIGHLIGHT
    commit id:'Loki config.'
    commit id:'Loki install' type: HIGHLIGHT
    commit id:'Traefik Proxy config.'
    commit id:'Traefik Proxy install' type: HIGHLIGHT
    commit id:'Flux config. for multitenants'
    commit id:'Flux config. for TEST tenant'
    commit id:'namespace isolation by RBAC'

    branch TEST-env order:1
    commit id:'ROCKY tenant creation'
    checkout OPS
    commit id:'ROCKY deploy. config.'

    checkout TEST-env
    merge OPS id:'TEST ready to deploy ROCKY'

    checkout ROCKY
    commit id:'ROCKY' tag:'v1.0.0'

    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.0' type: HIGHLIGHT

    checkout OPS
    commit id:'ROCKY patch for ingress config.' tag:'R03'
    checkout TEST-env
    merge OPS id:'ingress config. for ROCKY app' type: HIGHLIGHT

    checkout ROCKY
    commit id:'blue color' tag:'v1.0.1'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.1' type: HIGHLIGHT

    checkout ROCKY
    commit id:'pink color' tag:'v1.0.2'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.2' type: HIGHLIGHT

    checkout OPS
    commit id:'FLUX config for MOVY deployment'
    checkout TEST-env
    merge OPS id:'FLUX ready to deploy MOVY'

    checkout MOVY
    commit id:'MOVY' tag:'v1.0.3'
    checkout TEST-env
    merge MOVY tag:'MOVY v1.0.3' type: REVERSE

    checkout OPS
    commit id:'Network policies'
    checkout TEST-env
    merge OPS type: HIGHLIGHT

    checkout OPS
    commit id:'FLUX config. for OLM deployment'
    checkout TEST-env
    merge OPS id:'OLM deployment' type: HIGHLIGHT
    checkout OPS
    commit id:'FLUX config. for CloudNative-PG deployment'
    checkout TEST-env
    merge OPS id:'CloudNative-PG deployment' type: HIGHLIGHT

    checkout MOVY
    commit id:'connection to CloudNative-PG cluster'
    checkout TEST-env
    merge MOVY tag:'MOVY v1.0.3' type: HIGHLIGHT

    checkout OPS
    commit id:'k0s install on METAL cluster'
    commit id:'Flux config. for METAL cluster'
    branch METAL_TEST-PROD order:3
    commit id:'ROCKY/MOVY tenants on METAL' type: HIGHLIGHT
    checkout OPS
    commit id:'Flux config. for OpenEBS'
    checkout METAL_TEST-PROD
    merge OPS id:'openEBS on METAL' type: HIGHLIGHT

    checkout OPS
    commit id:'Kyverno install'
    commit id:'Kyverno rules'
    checkout TEST-env
    merge OPS type: HIGHLIGHT

    checkout OPS
    commit id:'Flux config. for PROD tenant' tag:'P01'
    branch PROD-env order:2
    commit id:'ROCKY tenant on PROD'
    checkout OPS
    commit id:'ROCKY patch for PROD' tag:'R04'
    checkout PROD-env
    merge OPS id:'PROD ready to deploy ROCKY' type: HIGHLIGHT
    checkout PROD-env
    merge ROCKY tag:'ROCKY v1.0.2'

    checkout MOVY
    commit id:'MOVY HELM chart' tag:'M03'
    checkout TEST-env
    merge MOVY tag:'MOVY v1.0'
</pre>
