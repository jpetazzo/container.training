# R01- Configuring **_🎸ROCKY_** deployment with Flux

The **_⚙️OPS_** team manages 2 distinct envs: **_⚗️TEST_** et _**🚜PROD**_

Thanks to _Kustomize_
  1. it creates a **_base_** common config
  2. this common config is overwritten with a **_⚗️TEST_** _tenant_-specific configuration
  3. the same applies with a _**🚜PROD**_-specific configuration

> 💡 This seems complex, but no worries: Flux's CLI handles most of it.

---

## Creating the **_🎸ROCKY_**-dedicated _tenant_ in **_⚗️TEST_** env

- Using the `flux` _CLI_, we create the file configuring the **_🎸ROCKY_** team's dedicated _tenant_…
- … this file takes place in the `base` common configuration for both envs

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    mkdir -p ./tenants/base/rocky &&       \
    flux create tenant rocky               \
        --with-namespace=rocky-test        \
        --cluster-role=rocky-full-access   \
        --export > ./tenants/base/rocky/rbac.yaml
```

]

---

class: extra-details

### 📂 ./tenants/base/rocky/rbac.yaml

Let's see our file…

3 resources are created: `Namespace`, `ServiceAccount`, and `ClusterRoleBinding`

`Flux` **impersonates** as this `ServiceAccount` when it applies any resources found in this _tenant_-dedicated source(s)

- By default, the `ServiceAccount` is bound to the `cluster-admin` `ClusterRole`
- The team maintaining the sourced `Github` repository is almighty at cluster scope

A not that much isolated _tenant_! 😕

That's why the **_⚙️OPS_** team enforces specific `ClusterRoles` with restricted permissions

Let's create these permissions!

---

## _namespace_ isolation for **_🎸ROCKY_**

.lab[

- Here are the restricted permissions to use in the `rocky-test` `Namespace`

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cp ~/container.training/k8s/M6-rocky-cluster-role.yaml ./tenants/base/rocky/
```

]

> 💡 Note that some resources are managed at cluster scope (like `PersistentVolumes`).
> We need specific permissions, then…

---

## Creating `Github` source in Flux for **_🎸ROCKY_** app repository

A specific _branch_ of the `Github` repository is monitored by the `Flux` source

.lab[

- ⚠️ you may change the **repository URL** to the one of your own clone

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create source git rocky-app \
    --namespace=rocky-test                                                  \
    --url=https://github.com/Musk8teers/container.training-spring-music/    \
    --branch=rocky  --export > ./tenants/base/rocky/sync.yaml
```

]

---

## Creating `kustomization` in Flux for **_🎸ROCKY_** app repository

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization rocky \
    --namespace=rocky-test                                                 \
    --service-account=rocky                                                \
    --source=GitRepository/rocky-app                                       \
    --path="./k8s/" --export >> ./tenants/base/rocky/sync.yaml

k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cd ./tenants/base/rocky/ &&            \
    kustomize create --autodetect &&       \
    cd -
```

]

---

class: extra-details

### 📂 Flux config files

Let's review our `Flux` configuration files

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cat ./tenants/base/rocky/sync.yaml &&  \
    cat ./tenants/base/rocky/kustomization.yaml
```

]

---

## Adding a kustomize patch for **_⚗️TEST_** cluster deployment

💡 Remember the DRY strategy!

- The `Flux` tenant-dedicated configuration is looking for this file: `.tenants/test/rocky/kustomization.yaml`  
- It has been configured here: `clusters/CLOUDY/tenants.yaml`

- All the files we just created are located in `.tenants/base/rocky`
- So we have to create a specific kustomization in the right location

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \ 
    mkdir -p ./tenants/test/rocky &&       \
    cp ~/container.training/k8s/M6-rocky-test-patch.yaml ./tenants/test/rocky/ && \
    cp ~/container.training/k8s/M6-rocky-test-kustomization.yaml ./tenants/test/rocky/kustomization.yaml
```

---

### Synchronizing Flux config with its Github repo

Locally, our `Flux` config repo is ready  
The **_⚙️OPS_** team has to push it to `Github` for `Flux` controllers to watch and catch it!

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    git add . && \
    git commit -m':wrench: :construction_worker: add ROCKY tenant configuration' && \
    git push
```

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

class: pic

![rocky config files](images/flux/R01-config-files.png)

---

class: extra-details

### Flux resources for ROCKY tenant 1/2

.lab[

```bash
k8s@shpod:~$ flux get all -A
NAMESPACE       NAME                            REVISION                SUSPENDED
    READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:8ffd72cf      False
    True    stored artifact for revision 'main@sha1:8ffd72cf'
rocky-test      gitrepository/rocky-app         rocky@sha1:ffe9f3fe     False
    True    stored artifact for revision 'rocky@sha1:ffe9f3fe'
(…)
```

]

---

class: extra-details

### Flux resources for ROCKY _tenant_ 2/2

.lab[

```bash
k8s@shpod:~$ flux get all -A
(…)
NAMESPACE       NAME                            REVISION                SUSPENDED
    READY   MESSAGE
flux-system     kustomization/flux-system       main@sha1:8ffd72cf      False    
    True    Applied revision: main@sha1:8ffd72cf
flux-system     kustomization/tenant-prod                               False    
    False   kustomization path not found: stat /tmp/kustomization-1164119282/tenants/prod: no such file or directory
flux-system     kustomization/tenant-test       main@sha1:8ffd72cf      False    
    True    Applied revision: main@sha1:8ffd72cf
rocky-test      kustomization/rocky                                     False    
    False   StatefulSet/db dry-run failed (Forbidden): statefulsets.apps "db" is forbidden: User "system:serviceaccount:rocky-test:rocky" cannot patch resource "statefulsets" in API group "apps" at the cluster scope
```

]

And here is our 2nd Flux error(s)! 😅

---

class: extra-details

### Flux Kustomization, mutability, …

🔍 Notice that none of the expected resources is created:  
the whole kustomization is rejected, even if the `StatefulSet` is this only resource that fails!

🔍 Flux Kustomization uses the dry-run feature to templatize the resources and then applying patches onto them  
Good but some resources are not completely mutable, such as `StatefulSets`

We have to fix the mutation by applying the change without having to patch the resource.

🔍 Simply add the `spec.targetNamespace: rocky-test` to the `Kustomization` named `rocky`

---

class: extra-details

## And then it's deployed 1/2

You should see the following resources in the `rocky-test` namespace

.lab[

```bash
k8s@shpod-578d64468-tp7r2 ~/$ k get pods,svc,deployments -n rocky-test
NAME                       READY   STATUS         RESTARTS      AGE
pod/db-0                   1/1     Running        0             47s
pod/web-6c677bf97f-c7pkv   0/1     Running        1 (22s ago)   47s
pod/web-6c677bf97f-p7b4r   0/1     Running        1 (19s ago)   47s

NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/db    ClusterIP   10.32.6.128   <none>        5432/TCP   48s
service/web   ClusterIP   10.32.2.202   <none>        80/TCP     48s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   0/2     2            0           47s
```

]

---

class: extra-details

## And then it's deployed 2/2

You should see the following resources in the `rocky-test` namespace

.lab[

```bash
k8s@shpod-578d64468-tp7r2 ~/$ k get statefulsets,pvc,pv -n rocky-test
NAME                       READY   AGE
statefulset.apps/db        1/1     47s

NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/postgresql-data-db-0   Bound    pvc-c1963a2b-4fc9-4c74-9c5a-b0870b23e59a   1Gi        RWO            sbs-default    <unset>                 47s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/postgresql-data                            1Gi        RWO,RWX        Retain           Available                                                    <unset>                          47s
persistentvolume/pvc-150fcef5-ebba-458e-951f-68a7e214c635   1G         RWO            Delete           Bound       shpod/shpod                       sbs-default    <unset>                          4h46m
persistentvolume/pvc-c1963a2b-4fc9-4c74-9c5a-b0870b23e59a   1Gi        RWO            Delete           Bound       rocky-test/postgresql-data-db-0   sbs-default    <unset>                          47s
```

]

---

class: extra-details

### PersistentVolumes are using a default `StorageClass`

💡 This managed cluster comes with custom `StorageClasses` leveraging on Cloud _IaaS_ capabilities (i.e. block devices)

![Flux configuration waterfall](images/flux/persistentvolumes.png)

- a default `StorageClass` is applied if none is specified (like here)
- for **_🏭PROD_** purpose, ops team might enforce a more performant `StorageClass`
- on a bare-metal cluster, **_🏭PROD_** team has to configure and provide `StorageClasses` on its own

---

class: pic

![Flux configuration waterfall](images/flux/flux-config-dependencies.png)

---


## Upgrading ROCKY app

The Git source named `rocky-app` is pointing at
- a Github repository named [Musk8teers/container.training-spring-music](https://github.com/Musk8teers/container.training-spring-music/)
- on its branch named `rocky`

This branch deploy the v1.0.0 of the _Web_ app:
`spec.template.spec.containers.image: ghcr.io/musk8teers/container.training-spring-music:1.0.0`

What happens if the **_🎸ROCKY_** team upgrades its branch to deploy `v1.0.1` of the _Web_ app?

---

## _tenant_ **_🏭PROD_**

💡 **_🏭PROD_** _tenant_ is still waiting for its `Flux` configuration, but don't bother for it right now.

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

    checkout OPS
    commit id:'ROCKY deploy. config.' tag:'R01'

    checkout TEST-env
    merge OPS id:'TEST ready to deploy ROCKY' type: HIGHLIGHT tag:'R02'

    checkout ROCKY
    commit id:'ROCKY' tag:'v1.0.0'

    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.0'

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

    checkout OPS
    commit id:'Ingress-controller config.' tag:'T05'
    checkout TEST-env
    merge OPS id:'Ingress-controller install' type: HIGHLIGHT tag:'T06'

    checkout OPS
    commit id:'ROCKY patch for ingress config.' tag:'R03'
    checkout TEST-env
    merge OPS id:'ingress config. for ROCKY app'

    checkout ROCKY
    commit id:'blue color' tag:'v1.0.1'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.1'

    checkout ROCKY
    commit id:'pink color' tag:'v1.0.2'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.2'

    checkout OPS
    commit id:'FLUX config for MOVY deployment' tag:'M01'
    checkout TEST-env
    merge OPS id:'FLUX ready to deploy MOVY' type: HIGHLIGHT tag:'M02'

    checkout MOVY
    commit id:'MOVY' tag:'v1.0.3'
    checkout TEST-env
    merge MOVY tag:'MOVY v1.0.3' type: REVERSE

    checkout OPS
    commit id:'Network policies'
    checkout TEST-env
    merge OPS type: HIGHLIGHT
</pre>
