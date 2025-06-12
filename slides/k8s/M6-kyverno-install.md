## introducing Kyverno

Kyverno is a tool to extend Kubernetes permission management to express complex policies…
</br>… and override manifests delivered by client teams.

---

class: extra-details

### Kyverno -- for more info

Please, refer to the [`Setting up Kubernetes` chapter in the High Five M4 module](./4.yml.html#toc-policy-management-with-kyverno) for more infos about `Kyverno`.

---

## Creating an `Helm` source in Flux for OpenEBS Helm chart

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$  \
        mkdir -p clusters/CLOUDY/kyverno && \
        cp -pr ~/container.training/k8s/

k8s@shpod ~$ flux create source helm kyverno \
    --namespace=kyverno                         \
    --url=https://kyverno.github.io/kyverno/ \
    --interval=3m                            \
    --export > ./clusters/CLOUDY/kyverno/sync2.yaml
```

]

---

## Creating the `HelmRelease` in Flux

.lab[

```bash
k8s@shpod ~$ flux create helmrelease kyverno    \
    --namespace=kyverno                         \
    --source=HelmRepository/kyverno.flux-system \
    --target-namespace=kyverno                  \
    --create-target-namespace=true              \
    --chart-version=">=3.4.2"                   \
    --chart=kyverno                             \
    --export >> ./clusters/CLOUDY/kyverno/sync.yaml
```

]

---

## Add Kyverno policy

This polivy is just an example.
It enforces the use of a `Service Account` in `Flux` configurations

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$           \
    mkdir -p clusters/CLOUDY/kyverno-policies &&     \
    cp -pr ~/container.training/k8s/M6-kyverno-enforce-service-account.yaml \
            ./clusters/CLOUDY/kyverno-policies/

---

### Creating `kustomization` in Flux for Kyverno policies

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$           \
    flux create kustomization kyverno-policies       \
        --namespace=kyverno                          \
        --source=GitRepository/flux-system           \
        --path="./clusters/CLOUDY/kyverno-policies/" \
        --prune true --interval 5m                   \
        --depends-on kyverno                         \
        --export >> ./clusters/CLOUDY/kyverno-policies/sync.yaml
```

]


## Apply Kyverno policy
```bash
flux create kustomization 

--path 
--source GitRepository/
--export > ./clusters/CLOUDY/kyverno-policies/sync.yaml
```

---

## Add Kyverno dependency for **_⚗️TEST_** cluster

- Now that we've got `Kyverno` policies,
- ops team will enforce any upgrade from any kustomization in our dev team tenants
- to wait for the `kyverno` policies to be reconciled (in a `Flux` perspective)

- upgrade file `./clusters/CLOUDY/tenants.yaml`,
- by adding this property:  `spec.dependsOn.{name: kyverno-policies}`

---

class: pic

![Running Mario](images/M6-running-Mario.gif)

---

### Debugging

`Kyverno-policies` `Kustomization` failed because `spec.dependsOn` property can only target a resource from the same `Kind`.

- Let's suppress the `spec.dependsOn` property.

Now `Kustomizations` for **_🎸ROCKY_** and **_🎬MOVY_** tenants failed because of our policies.

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
    branch ROCKY order:4
    branch MOVY order:5
    branch YouRHere order:6

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
    merge OPS type: HIGHLIGHT tag:'T07'

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

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

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
