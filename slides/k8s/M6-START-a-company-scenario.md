# Using Kubernetes in an Enterprise-like scenario

- 💪🏼 Okay. Prior training modules provded detailed explainations of each topic

- 🤯 The 1st challenge any Kubernetes admin faces is choosing all these components to build a _Production-ready_ cluster

- 🎯 This module aims to simulate a day-to-day typical workflow in companies, exploring the steps needed to run containerized apps on such a _Prod-ready_ cluster

- We'll start by building our cluster and then enhance it by **adding features** one after another

---

## The plan

Our company consists of 3 teams: **_⚙️OPS_**, **_🎸ROCKY_** and **_🎬MOVY_**

- **_⚙️OPS_** is the platform engineering team responsible for building and configuring Kubernetes clusters

- Both **_🎸ROCKY_** and **_🎬MOVY_** develop Web apps that manage 💿 music albums
    - **_🎸ROCKY_** manages _rock & pop_ albums
    - **_🎬MOVY_** handles _movie soundtrack_ albums

- Each app resides in its own `Git` repository

- Both **_🎸ROCKY_** and **_🎬MOVY_** aim to code, build package and deploy their applications _in an autonomous way_

---

### Using 2 Kubernetes clusters

The **_⚙️OPS_** team manages 2 Kubernetes clusters

- **_☁️CLOUDY_** is a managed cluster from a public Cloud provider
  - It comes with pre-configured features upon delivery
  - HA control plane
  - 2 dedicated worker nodes
  - The **_⚙️OPS_** team uses `Scaleway Kapsule` to deploy it (though other _KaaS_ options are available…)
  
- **_🤘METAL_** is a custom-built cluster installed on bare Linux servers
  - The **_⚙️OPS_** team needs to configure many components on its own
  - HA control plane
  - 3 worker nodes (also hosting control plane components)
  - The **_⚙️OPS_** team uses `k0s` to install it (though other distros are available as well…)

---

### Using several envs for each dev team

The **_⚙️OPS_** team creates 2 environments for each dev team: **_⚗️TEST_** and **_🏭PROD_**

- the setup for each env and cluster should adopt an automated and DRY approach to ensure configurations are consistent and to minimize maintainance
  
- each cluster and each env has it's **own lifecycle** (adding an extra component/feature may be done on one env without impacting the other)

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

- **_🎸ROCKY_** uses a `Flux` _GitOps_ workflow based on regular Kubernetes `YAML` resources

- **_🎬MOVY_** uses a `Flux` _GitOps_ workflow based on `Helm` charts

---

## 🍱 What features?

<!-- TODO: complete this slide when all the modules are there -->
The **_⚙️OPS_** team aims to provide clusters offering the following features to its users:

- a network stack with efficient workload isolation

- ingress and load-balancing capabilites

- an enterprise-grade monitoring solution for real-time insights

- automated policy rule enforcement to control Kubernetes resources requested by dev teams

<!-- - HA PostgreSQL -->

<!-- - HTTPs certificates to expose the applications -->

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
    commit id:'Flux install on CLOUDY cluster' tag:'T01'
    branch CLOUDY-cluster_TEST-env order:1
    commit id:'FLUX install on TEST' tag:'T02' type: HIGHLIGHT

    checkout OPS
    commit id:'ROCKY config.' tag:'T03'
    checkout CLOUDY-cluster_TEST-env
    merge OPS id:'ROCKY tenant creation' tag:'T04'

    checkout OPS
    commit id:'ROCKY deploy. config.' tag:'R01'

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
