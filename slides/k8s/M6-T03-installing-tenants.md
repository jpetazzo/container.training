# Multi-tenants management with Flux

💡 Thanks to `Flux`, we can manage Kubernetes resources from inside the clusters.

The **_⚙️OPS_** team uses `Flux` with a _GitOps_ code base to:
- configure the clusters
- deploy tools and components to extend the clusters capabilites
- configure _GitOps_ workflow for dev teams in **dedicated and isolated tenants**

The **_🎸ROCKY_** team uses `Flux` to deploy every new release of its app, by detecting every new `git push` events happening in its app `Github` repository


The **_🎬MOVY_** team uses `Flux` to deploy every new release of its app, packaged and published in a new `Helm` chart release

---

## Creating tenants with Flux

While basic `Flux` behavior is to use a single configuration directory applied by a cluster-wide role…

… it can also enable _multi-tenant_ configuration by:
- creating dedicated directories for each tenant in its configuration code base
- and using a dedicated `ServiceAccount` with limited permissions to operate in each tenant

Several tenants are created
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

### The command line 1/2

Creating the **_⚗️TEST_** tenant

.lab[

```bash
shpod:~# cd fleet-config-using-flux-XXXXX/
shpod:~/fleet-config-using-flux-lpiot# flux create kustomization tenants \
    --namespace=flux-system            \
    --source=GitRepository/flux-system \
    --path ./tenants/test              \
    --prune                            \
    --interval=1m                      \
    --export >> clusters/CLOUDY/tenants.yaml
```

]

---

### The command line 2/2

Then we create the **_🏭PROD_** tenant

.lab[

```bash
shpod:~/fleet-config-using-flux-lpiot# flux create kustomization tenants \
    --namespace=flux-system            \
    --source=GitRepository/flux-system \
    --path ./tenants/prod              \
    --prune                            \
    --interval=3m                      \
    --export >> clusters/CLOUDY/tenants.yaml
```

]

---

### 📂 Flux tenants.yaml files

Let's review the `fleet-config-using-flux-XXXXX/clusters/CLOUDY/tenants.yaml` file




⚠️ The last command we type in `Flux` _CLI_ creates the `YAML` manifest **locally**

> ☝🏻 Don't forget to `git commit` and `git push` to `Github`!

---

### Our 1st Flux error

.lab[

```bash
shpod:~/fleet-config-using-flux-lpiot# flux get all
NAMESPACE       NAME                            REVISION                SUSPENDED
      READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:4db19114      False
      True    stored artifact for revision 'main@sha1:4db19114'

NAMESPACE       NAME                            REVISION                SUSPENDED
      READY   MESSAGE                                 
flux-system     kustomization/flux-system       main@sha1:d48291a8      False
      False   kustomize build failed: accumulating resources: accumulation err='accumulating resources from './tenants.yaml': may not add resource with an already registered id: Kustomization.v1.kustomize.toolkit.fluxcd.io/tenants.flux-system': must build at directory: '/tmp/kustomization-689086759/clusters/CLOUDY/tenants.yaml': file is not directory
```

]

> Our configuration may be incomplete 😅

---

## Configuring Flux for the **_🎸ROCKY_** team

What the **_⚙️OPS_** team has to do:

- 🔧 Create a dedicated `rocky` _tenant_ for _**⚗️TEST**_ and **_🏭PROD_** envs on the cluster

- 🔧 Create the `Flux` source pointing to the `Github` repository embedding the **_🎸ROCKY_** app source code

- 🔧 Add a `kustomize` _patch_ into the global `Flux` config to include this specific `Flux` config. dedicated to the deployment of the **_🎸ROCKY_** app

What the **_🎸ROCKY_** team has to do:

- 👨‍💻 Create the `kustomization.yaml` file in the **_🎸ROCKY_** app source code repository on `Github`
