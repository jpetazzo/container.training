## Introducing Kyverno

Kyverno is a tool to extend Kubernetes permission management to express complex policies…
</br>… and override manifests delivered by client teams.

---

class: extra-details

### Kyverno -- for more info

Please, refer to the [`Setting up Kubernetes` chapter in the High Five M4 module](./4.yml.html#toc-policy-management-with-kyverno) for more infos about `Kyverno`.

---

### Creating `kustomization` in Flux for Kyverno stack

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization kyverno \
    --namespace=flux-system                                                  \
    --source=GitRepository/catalog                                           \
    --path="./k8s/flux/kyverno/"                                             \
    --export >> ./clusters/CLOUDY/install-components/sync-kyverno.yaml
```

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

## Adding Kyverno policies

This policy is just an example.
It enforces the use of a `Service Account` in `Flux` configurations

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization kyverno-policies \
    --namespace=flux-system                                                           \
    --source=GitRepository/catalog                                                    \
    --path="./k8s/flux/kyverno-policies/"                                             \
    --export >> ./clusters/CLOUDY/install-components/sync-kyverno-policies.yaml
```

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

## Add Kyverno dependency for **_⚗️TEST_** cluster

- Now that we've got `Kyverno` policies,
- ops team will enforce any upgrade from any kustomization in our dev team tenants
- to wait for the `kyverno` policies to be reconciled (in a `Flux` perspective)

- upgrade file `./clusters/CLOUDY/tenants.yaml`,
- by adding this property:  `spec.dependsOn.{name: kyverno-policies}`

---

class: pic

![Running Mario](images/running-mario.gif)

---

class: extra-details

### Debugging

- In a former session `Kyverno-policies` `Kustomization` failed because `spec.dependsOn` property can only target a resource from the same `Kind`.  

- And it was targetting `Kyverno` HelmRelease. Now we only have dependency on `Kustomization` with our `install-components` extra step.

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
