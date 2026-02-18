# Configuring **_🎬MOVY_** deployment with Flux

**_🎸ROCKY_** _tenant_ is now fully usable in **_⚗️TEST_** env, let's do the same for another _dev_ team: **_🎬MOVY_**

😈 We could do it by using `Flux` _CLI_,  
but let's see if we can succeed by just adding manifests in our `Flux` configuration repository.

---

class: pic

![Flux configuration waterfall](images/flux/flux-config-dependencies.png)

---

## Impact study

In our `Flux` configuration repository:

- Creation of the following 📂 folders: `./tenants/[base|test]/MOVY`

- Modification of the following 📄 file: `./clusters/CLOUDY/tenants.yaml`?
  - Well, we don't need to: the watched path include the whole `./tenants/[test]/*` folder

In the app repository:

- Creation of a `movy` branch to deploy another version of the app dedicated to movie soundtracks

---

### Creation of the 📂 folders

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cp -pr tenants/base/rocky tenants/base/movy
    cp -pr tenants/test/rocky tenants/test/movy
```

]

---

### Modification of tenants/[base|test]/movy/* 📄 files

- For 📄`M6-rocky-*.yaml`, change the file names…
  - and update the 📄`kustomization.yaml` file as a result

- In any file, replace any `rocky` entry by `movy`

- In 📄 `sync.yaml` be aware of what repository and what branch you want `Flux` to watch for **_🎬MOVY_** app deployment.
  - for this demo, let's assume we create a `movy` branch

---

class: extra-details

### What about reusing rocky-cluster-roles?

💡 In 📄`M6-movy-cluster-role.yaml` and 📄`rbac.yaml`, we could have reused the already existing `ClusterRoles`: `rocky-full-access`, and `rocky-pv-access`  

A `ClusterRole` is cluster wide. It is not dedicated to a namespace.  
- Its permissions are restrained to a specific namespace by being bound to a `ServiceAccount` by a `RoleBinding`.
- Whereas a `ClusterRoleBinding` extends the permissions to the whole cluster scope.  

But a _tenant_ is a **_tenant_** and permissions might evolved separately for **_🎸ROCKY_** and **_🎬MOVY_**.

So [we got to keep'em separated](https://www.youtube.com/watch?v=GHUql3OC_uU).

---

### Let-su-go!

The **_⚙️OPS_** team push this new tenant configuration to `Github` for `Flux` controllers to watch and catch it!

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    git add . && \
    git commit -m':wrench: add MOVY tenant configuration' && \
    git push
```

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

class: extra-details

### Another Flux error?

.lab[

- It seems that our `movy` branch is not present in the app repository

```bash
k8s@shpod:~$ flux get kustomization -A
NAMESPACE    NAME         REVISION   SUSPENDED  MESSAGE
(…)
flux-system  tenant-prod  False      False      kustomization path not found:
stat /tmp/kustomization-113582828/tenants/prod: no such file or directory
(…)
movy-test    movy         False      False      Source artifact not found,
retrying in 30s                                                             
```

]

---

### Creating the `movy` branch

- Let's create this new `movy` branch from `rocky` branch

.lab[

- You can force immediate reconciliation by typing this command:

```bash
k8s@shpod:~$ flux reconcile source git movy-app -n movy-test
```

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### New branch detected

- You now have a second app responding on [http://movy.test.enix.thegaragebandofit.com]  

  - But as of now, it's just the same as the **_🎸ROCKY_** one.  

- We want a specific (pink-colored) version with a dataset full of movie soundtracks.

---

## New version of the **_🎬MOVY_** app

In our branch `movy`…  
Let's modify our `deployment.yaml` file with 2 modifications.

- in `spec.template.spec.containers.image` change the container image tag to `1.0.3`

- and… let's introduce some evil enthropy by changing this line… 😈😈😈

```yaml
 value: jdbc:postgresql://db/music
```

by this one

```yaml
 value: jdbc:postgresql://db.rocky-test/music
```

And push the modifications…

---

class: pic

![MOVY app has an incorrect dataset](images/flux/incorrect-dataset-in-MOVY-app.png)

---

class: pic

![ROCKY app has an incorrect dataset](images/flux/incorrect-dataset-in-ROCKY-app.png)

---

### MOVY app is connected to ROCKY database

How evil have we been! 😈  
We connected the **_🎬MOVY_** app to the **_🎸ROCKY_** database.

Even if our tenants are isolated in how they manage their Kubernetes resources…  
pod network is still full mesh and any connection is authorized.

> The **_⚙️OPS_** team should fix this!

---

class: extra-details

## Adding NetworkPolicies to **_🎸ROCKY_** and **_🎬MOVY_** namespaces

`Network policies` may be seen as the firewall feature in the pod network.  
They rules ingress and egress network connections considering a described subset of pods.

Please, refer to the [`Network policies` chapter in the High Five M4 module](./4.yml.html#toc-network-policies)

- In our case, we just add the file `~/container.training/k8s/flux/tenants/base/rocky/network-policies.yaml`
</br>in our `./tenants/base/rocky` folder

- and the same for `./tenants/base/rocky` folder

- without forgetting to update our `kustomization.yaml` file

- and without forgetting to commit 😁

---

class: pic

![Running Mario](images/running-mario.gif)

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

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

    checkout OPS
    commit id:'k0s install on METAL cluster' tag:'K01'
    commit id:'Flux config. for METAL cluster' tag:'K02'
    branch METAL_TEST-PROD order:3
    commit id:'ROCKY/MOVY tenants on METAL' type: HIGHLIGHT
    checkout OPS
    commit id:'Flux config. for OpenEBS' tag:'K03'
    checkout METAL_TEST-PROD
    merge OPS id:'openEBS on METAL' type: HIGHLIGHT

    checkout OPS
    commit id:'Prometheus install'
    checkout TEST-env
    merge OPS type: HIGHLIGHT

    checkout OPS
    commit id:'Kyverno install'
    commit id:'Kyverno rules'
    checkout TEST-env
    merge OPS type: HIGHLIGHT
</pre>
