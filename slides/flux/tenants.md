# Multi-tenants management with Flux

💡 Thanks to `Flux`, we can manage Kubernetes resources from inside the clusters.

The **_⚙️OPS_** team uses `Flux` with a _GitOps_ code base to:
- configure the clusters
- deploy tools and components to extend the clusters capabilites
- configure _GitOps_ workflow for dev teams in **dedicated and isolated _tenants_**

The **_🎸ROCKY_** team uses `Flux` to deploy every new release of its app, by detecting every new `git push` events happening in its app `Github` repository


The **_🎬MOVY_** team uses `Flux` to deploy every new release of its app, packaged and published in a new `Helm` chart release

---

## Creating _tenants_ with Flux

While basic `Flux` behavior is to use a single configuration directory applied by a cluster-wide role…

… it can also enable _multi-tenant_ configuration by:
- creating dedicated directories for each _tenant_ in its configuration code base
- and using a dedicated `ServiceAccount` with limited permissions to operate in each _tenant_

Several _tenants_ are created
- per env
    - for **_⚗️TEST_**
    - and **_🏭PROD_**
- per team
    - for **_🎸ROCKY_**
    - and **_🎬MOVY_**

---

class: pic

![Multi-tenants clusters](images/M6-cluster-multi-tenants.png )

---

### Flux CLI works locally

First, we have to **locally** clone your `Flux` configuration `Github` repository

- create an ssh key pair
- add the **public** key to your `Github` repository (**with write access**)
- and git clone the repository

---

### The command line 1/2

Creating the **_⚗️TEST_** _tenant_

.lab[

- ⚠️ Think about renaming the repo with your own suffix
```bash
k8s@shpod:~$ cd fleet-config-using-flux-XXXXX/
k8s@shpod:~/fleet-config-using-flux-XXXXX$     \
    flux create kustomization tenant-test      \
        --namespace=flux-system                \
        --source=GitRepository/flux-system     \
        --path ./tenants/test                  \
        --interval=1m                          \
        --prune --export >> clusters/CLOUDY/tenants.yaml
```

]

---

### The command line 2/2

Then we create the **_🏭PROD_** _tenant_

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    flux create kustomization tenant-prod  \
        --namespace=flux-system            \
        --source=GitRepository/flux-system \
        --path ./tenants/prod              \
        --interval=3m                      \
        --prune --export >> clusters/CLOUDY/tenants.yaml
```

]

---

### 📂 Flux tenants.yaml files

Let's review the `fleet-config-using-flux-XXXXX/clusters/CLOUDY/tenants.yaml` file




⚠️ The last command we type in `Flux` _CLI_ creates the `YAML` manifest **locally**

> ☝🏻 Don't forget to `git commit` and `git push` to `Github`!

---

class: pic

![Running Mario](images/M6-running-Mario.gif)

---

### Our 1st Flux error

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux get all
NAMESPACE       NAME                            REVISION                SUSPENDED
    READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:0466652e      False
    True    stored artifact for revision 'main@sha1:0466652e'

NAMESPACE       NAME                            REVISION                SUSPENDED
    READY   MESSAGE
kustomization/flux-system       main@sha1:0466652e      False           True
    Applied revision: main@sha1:0466652e
kustomization/tenant-prod                               False           False
    kustomization path not found: stat /tmp/kustomization-417981261/tenants/prod: no such file or directory
kustomization/tenant-test                               False           False
    kustomization path not found: stat /tmp/kustomization-2532810750/tenants/test: no such file or directory
```

]

> Our configuration may be incomplete 😅

---

## Configuring Flux for the **_🎸ROCKY_** team

What the **_⚙️OPS_** team has to do:

- 🔧 Create a dedicated `rocky` _tenant_ for **_⚗️TEST_** and **_🏭PROD_** envs on the cluster

- 🔧 Create the `Flux` source pointing to the `Github` repository embedding the **_🎸ROCKY_** app source code

- 🔧 Add a `kustomize` _patch_ into the global `Flux` config to include this specific `Flux` config. dedicated to the deployment of the **_🎸ROCKY_** app

What the **_🎸ROCKY_** team has to do:

- 👨‍💻 Create the `kustomization.yaml` file in the **_🎸ROCKY_** app source code repository on `Github`

---

### 🗺️ Where are we in our scenario?

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
    branch MOVY order:4
    branch YouRHere order:5

    checkout OPS
    commit id:'Flux install on CLOUDY cluster' tag:'T01'
    branch TEST-env order:1
    commit id:'FLUX install on TEST' tag:'T02' type: HIGHLIGHT

    checkout OPS
    commit id:'Flux config. for TEST tenant' tag:'T03'
    commit id:'namespace isolation by RBAC'
    checkout TEST-env
    merge OPS id:'ROCKY tenant creation' tag:'T04'

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

    checkout OPS
    commit id:'ROCKY deploy. config.' tag:'R01'

    checkout TEST-env
    merge OPS id:'TEST ready to deploy ROCKY' type: HIGHLIGHT tag:'R02'

    checkout ROCKY
    commit id:'ROCKY' tag:'v1.0.0'

    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.0'
</pre>
