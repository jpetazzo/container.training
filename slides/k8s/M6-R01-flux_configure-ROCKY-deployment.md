# R01- Configuring **_🎸ROCKY_** deployment with Flux

The **_⚙️OPS_** team manages 2 distinct envs: _**⚗️TEST**_ et _**🚜PROD**_
Thanks to _Kustomize_
  1. it creates a **_base_** common config
  2. this common config is overwritten with a _**⚗️TEST**_ _tenant_-specific configuration
  3. the same applies with a _**🚜PROD**_-specific configuration

> 💡 This seems complex, but no worries: Flux's CLI handles the essentials.

---

## Creating the **_🎸ROCKY_**-dedicated _tenant_ in _**⚗️TEST**_ env

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

### 📂 ./tenants/base/rocky/rbac.yaml

Let's see our file…

3 resources are created:

- `Namespace`, 
- a `ServiceAccount` and
- a `ClusterRoleBinding`

`Flux` impersonates as this `ServiceAccount` when it applies any resources found in this tenant-dedicated source(s)
By default, the `ServiceAccount` is bound to a `ClusterRole` named `cluster-admin`  

It means that, any team that maintain the sourced `Github` repository is able to apply Kubernetes resources as `cluster-admin`  
A not that much isolated tenant! 😕

That's why the **_⚙️OPS_** team forces a binding to a specific `ClusterRole`  
Let's create this ClusterRole permissions!

---

## _namespace_ isolation for **_🎸ROCKY_**


.lab[

- Here is a `ClusterRole` with permissions restricted to the dedicated `Namespace`
```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cp ~/container.training/k8s/M6-rocky-cluster-role.yaml ./tenants/base/rocky/
```

]

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
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization rocky \
    --namespace=rocky-test                                                 \
    --service-account=rocky                                                \
    --source=GitRepository/rocky-app                                       \
    --path="./k8s/" --export >> ./tenants/base/rocky/sync.yaml
k8s@shpod:~/fleet-config-using-flux-XXXXX$ cd ./tenants/base/rocky/ && \
    kustomize create --autodetect && cd -
```

]

---

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

## Adding a kustomize patch for _**⚗️TEST**_ cluster deployment

Remember!  
The `Flux` tenant-dedicated configuration is looking for this file `.tenants/test/rocky/kustomization.yaml`  
It has been configured here: `clusters/CLOUDY/tenants.yaml`

All the files we just created are located in `.tenants/base/rocky` (remember the DRY strategy)

So we have to create a specific kustomization in the right location

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \ 
    mkdir -p ./tenants/test/rocky &&       \
    cp ~/container.training/k8s/M6-rocky-test-patch.yaml ./tenants/test/rocky/ && \
    cp ~/container.training/k8s/M6-rocky-test-kustomization.yaml ./tenants/test/rocky/kustomization.yaml
```

---

### Synchronizing Flux config with its Github repo

Locally, our `Flux` config repo is ready  
The ops team has to push it to `Github`

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

![rocky config files](images/M6-R01-config-files.png)

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

### Flux resources for ROCKY tenant 2/2

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

## And then it's deployed

You should see the following resources in the `rocky-test` namespace

.lab[

```bash
k8s@shpod-578d64468-tp7r2 ~/$ k get all -n rocky-test
NAME                       READY   STATUS         RESTARTS      AGE
pod/db-0                   1/1     Running        0             47s
pod/web-6c677bf97f-c7pkv   0/1     Running        1 (22s ago)   47s
pod/web-6c677bf97f-p7b4r   0/1     Running        1 (19s ago)   47s

NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/db    ClusterIP   10.32.6.128   <none>        5432/TCP   48s
service/web   ClusterIP   10.32.2.202   <none>        80/TCP     48s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   0/2     2            0           47s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-6c677bf97f   2         2         0       47s

NAME                       READY   AGE
statefulset.apps/db        1/1     47s
```

]

---

## Upgrading ROCKY app

The Git source named `rocky-app` is pointing at
- a Github repository named [https://github.com/Musk8teers/container.training-spring-music/]
- on its branch named `rocky`

This branch deploy the v1.0.0 of the _Web_ app:
`spec.template.spec.containers.image: ghcr.io/musk8teers/container.training-spring-music:1.0.0`

What happens if we upgrade this branch to deploy `v1.0.1` of the _Web_ app?

---

## tenant **_🏭PROD_**

**_🏭PROD_** tenant is still waiting for its `Flux` configuration, but don't bother for it right now.
