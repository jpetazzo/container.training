# Using Kubernetes in an Enterprise-like scenario

- 💪🏼 Okay. The former training modules explain each subject in-depth, and each feature one at-a-time

- 🤯 The 1st tricky thing any `k8s` admin encounters is to choose and configure all these components to build a _Production-ready_ `k8s` cluster

- 🎯 This module precisely aims to play a scenario of a day-to-day ordinary workflow in companies and see what we'll have to do to build such a _Prod-ready_ Kubernetes cluster

- As we've done it before, we'll start to build/provision our cluster and then improve it by **adding features** one after another

---

## The plan

In our company, we have 3 different teams, **_⚙️OPS_**, **_🎸ROCKY_** and **_🎬MOVY_**

- **_⚙️OPS_** is the platform engineer building and configuring Kubernetes clusters

- Both **_🎸ROCKY_** and **_🎬MOVY_** build Web apps that manage 💿 music albums
    - **_🎸ROCKY_** builds a Web app managing _rock & pop_ albums
    - **_🎬MOVY_** builds a Web app for _movie soundtrack_ albums

- Each app is stored in its own git repository

- Both **_🎸ROCKY_** and **_🎬MOVY_** want to code, build package and deploy their applications onto a `Kubernetes` _cluster_ _in an autonomous way_

---

### Using 2 Kubernetes clusters

**_⚙️OPS_** team will operate 2 `Kubernetes` clusters

- **_☁️CLOUDY_** is a managed cluster from a public Cloud provider.
  - It comes with many features already configured when the cluster is delivered
  - HA control plane
  - 2 dedicated worker nodes
  - **_⚙️OPS_** will use `Scaleway Kapsule` to deploy it (but many other _KaaS_ are available…)
  
- **_🤘METAL_** is a cluster we install _from scratch_ on bare Linux servers.
  - **_⚙️OPS_** team will need to configure many components on its own.
  - HA control plane
  - 3 worker nodes (also hosting control plane components)
  - **_⚙️OPS_** will use `k0s` to install it (but many other distros are available…)

---

### Using several envs for each dev team

**_⚙️OPS_** team will create 2 environment for each dev team : for **testing** and **production** purpose

- it should use tools to **industrialise creation** of both envs and both clusters
  
- each cluster and each env has it's **own lifecycle** (the addition or configuration of extra components/features may be done on one env and not the other)
  
- configurations must be as DRY as possible (to avoid inconsistency and minimize configuration maintainance)

---

### Multi-tenancy

Both **_🎸ROCKY_** and **_🎬MOVY_** teams should use **dedicated _"tenants"_** on each cluster/env

- **_🎸ROCKY_** should be able to deploy, upgrade and configure its own app in its dedicated **namespace** without anybody else involved

- and the same for **_🎬MOVY_**

- neither conflict nor collision should be allowed between the 2 apps or the 2 teams.

---

## The application

- Both dev teams are developping an app to manage music albums
  
- This app is mostly based upon a demo app based upon `Spring` framework: spring-music
  
- This lab uses a dedicated fork [container.training-spring-music](https://github.com/Musk8teers/container.training-spring-music):
  -  with 2 branches dedicated to our **_🎸ROCKY_** and **_🎬MOVY_** teams.

- The app is a 2-tiers app:
  - a `Java/Spring` Web app
  - a `PostgreSQL` database

---

### 📂 specific file: application.yaml

This is where we configure the application to use `PostgreSQL` database.  

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

**_⚙️OPS_** team offers 2 deployment strategies that dev teams may use in an autonomous way:

- **_🎸ROCKY_** will use a `Flux` _GitOps_ workflow based upon regular Kubernetes `YAML` resources

- **_🎬MOVY_** will use a `Flux` _GitOps_ workflow based upon `Helm` charts

---

## 🍱 What features?

<!-- TODO: complete this slide when all the modules are there -->
**_⚙️OPS_** team want its clusters to offers the _"best of breed"_ features to its users:

- a network stack that is able to isolate workloads one from another

- ingress and load-balancing capabilites

- a decent monitoring stack

- policy rules automation to control the kind of Kubernetes resources that are requested by dev teams

<!-- - HA PostgreSQL -->

<!-- - HTTPs certificates to expose the applications -->

---

## 🌰 In a nutshell

- 3 teams: **_⚙️OPS_**, **_🎸ROCKY_**, **_🎬MOVY_**

- 2 clusters: **_☁️CLOUDY_**, **_🤘METAL_**

- 2 envs per cluster and per dev team: **_⚗️TEST_**, **_🏭PROD_**

- 2 Web apps Java/Spring + PostgreSQL: one for pop and rock albums, another for movie soundtrack albums

- 2 deployment strategies: regular YAML resources + `Kustomize`, `Helm` charts


> 💻 `Flux` is used both
> - to operate the clusters
> - and to manage the _GitOps_ deployment workflows

---

### What our scenario might look like…

<!-- TODO: to upgrade according to the actual scenario that is eventually build -->
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
    branch ROCKY order:3
    branch CLASSY order:4

    checkout OPS
    commit id:'TEST cluster creation' tag:'T01'
    branch CLOUDY-cluster_TEST-env order:1
    commit id:'FLUX install on TEST' tag:'T02'

    checkout OPS
    commit id:'TEST cluster config.' tag:'T03'
    checkout CLOUDY-cluster_TEST-env
    merge OPS id:'setup of TEST cluster' tag:'T04'

    checkout OPS
    commit id:'FLUX config for ROCKY deployment' tag:'R01'

    checkout CLOUDY-cluster_TEST-env
    merge OPS id:'FLUX ready to deploy ROCKY' type: HIGHLIGHT tag:'R02'

    checkout ROCKY
    commit id:'ROCKY' tag:'v1.0'

    checkout CLOUDY-cluster_TEST-env
    merge ROCKY tag:'ROCKY v1.0'
    
    checkout CLASSY
    commit id:'CLASSY' tag:'v1.0'

    checkout CLASSY
    commit id:'CLASSY HELM chart' tag:'C01'

    checkout OPS
    commit id:'FLUX config for CLASSY deployment' tag:'C02'
    checkout CLOUDY-cluster_TEST-env
    merge OPS id:'FLUX ready to deploy CLASSY' type: HIGHLIGHT tag:'C03'

    checkout CLOUDY-cluster_TEST-env
    merge CLASSY tag:'CLASSY v1.0'
    
    checkout ROCKY
    commit id:'new color' tag:'v1.1'
    checkout CLOUDY-cluster_TEST-env
    merge ROCKY tag:'ROCKY v1.1'

    checkout CLOUDY-cluster_TEST-env
    commit id:'wrong namespace' type: REVERSE

    checkout OPS
    commit id:'namespace isolation'
    checkout CLOUDY-cluster_TEST-env
    merge OPS type: HIGHLIGHT

    checkout ROCKY
    commit id:'fix namespace' tag:'v1.1.1'
    checkout CLOUDY-cluster_TEST-env
    merge ROCKY tag:'ROCKY v1.1.1'

    checkout ROCKY
    commit id:'add a field' tag:'v1.2'
    checkout CLOUDY-cluster_TEST-env
    merge ROCKY tag:'ROCKY v1.2'

    checkout OPS
    commit id:'Kyverno install'
    commit id:'Kyverno rules'
    checkout CLOUDY-cluster_TEST-env
    merge OPS type: HIGHLIGHT

    checkout OPS
    commit id:'Network policies'
    checkout CLOUDY-cluster_TEST-env
    merge OPS type: HIGHLIGHT

    checkout OPS
    branch PROD-cluster order:2
    commit id:'FLUX install on PROD'
    commit id:'PROD cluster configuration'

    checkout OPS
    commit id:'Add OpenEBS'
    checkout CLOUDY-cluster_TEST-env
    merge OPS id:'patch dedicated to PROD' type: REVERSE
    checkout PROD-cluster
    merge OPS type: HIGHLIGHT
</pre>

---
