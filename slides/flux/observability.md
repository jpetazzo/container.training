# Install monitoring stack

The **_⚙️OPS_** team wants to have a real monitoring stack for its clusters.  

- `Prometheus` and `Grafana` to collect and request metrics

- `Loki` to gather and search into the logs

---

## Reviewing our monitoring components in our Flux components catalog

2 directories are available in our Flux folder:

- kube-prometheus-stack
    - install Prometheus and Grafana _via_ Helm charts
    - install Grafana dashboards dedicated to Flux insights
    - configure an Ingress to publicly expose the Web interfaces 

- loki
    - install Loki and Promtail _via_ Helm charts

Both are heavily inspired from [Flux2-monitoring example](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring)

---

### Creating `kustomization` in Flux for monitoring stack

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization monitoring \
    --namespace=flux-system                                                     \
    --source=GitRepository/catalog                                              \
    --path="./k8s/flux/kube-prometheus-stack/"                                  \
    --export >> ./clusters/CLOUDY/install-components/sync-monitoring.yaml
```

⚠ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

<!-- TODO: See where we can have these slides now!

---

## Flux repository synchro is broken😅

It seems that `Flux` on **_☁️CLOUDY_** cluster is not able to authenticate with `ssh` on its `Github` config repository!  

What happened?
When we install `Flux` on **_🤘METAL_** cluster, it generates a new `ssh` keypair and override the one used by **_☁️CLOUDY_** among the "deployment keys" of the `Github` repository.

⚠️ Beware of flux bootstrap command!

We have to
- generate a new keypair (or reuse an already existing one)
- add the private key to the Flux-dedicated secrets in **_☁️CLOUDY_** cluster
- add it to the "deployment keys" of the `Github` repository

---

### the command

.lab[

- `Flux` _CLI_ helps to recreate the secret holding the `ssh` **private** key.

```bash
k8s@shpod:~$ flux create secret git flux-system \
  --url=ssh://git@github.com/container-training-fleet/fleet-config-using-flux-XXXXX \
  --private-key-file=/home/k8s/.ssh/id_ed25519
```

- copy the **public** key into the deployment keys of the `Github` repository

]

---

class: pic

![Running Mario](images/running-mario.gif)
 -->
---

## Access the Grafana dashboard

.lab[

- Get the `Host` and `IP` address to request

```bash
k8s@shpod:~$ kubectl -n monitoring get ingress
NAME      CLASS   HOSTS                                           ADDRESS        PORTS   AGE
grafana   nginx   grafana.test.cloudy.enix.thegaragebandofit.com  62.210.39.83   80      6m30s
```

- Get the `Grafana` admin password

```bash
k8s@shpod:~$ k get secret kube-prometheus-stack-grafana -n monitoring \
                -o jsonpath='{.data.admin-password}' | base64 -d
```

]

⚠️ As of now, Ingress doesn't have public address. Something we have to work on!  
Meanwhile, we can use `kubectl port-forward`…

---

### And browse…

class: pic

![Grafana dashboard screenshot](images/flux/grafana-dashboard.png)

---

## Adding Loki to our obeervability stack

As of now, the 3rd dashboard is not available: no log aggregator is set up.

Loki is available in our component catalog. Let's add it!

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization loki \
    --namespace=flux-system                                               \
    --source=GitRepository/catalog                                        \
    --path="./k8s/flux/loki/"                                             \
    --export >> ./clusters/CLOUDY/install-components/sync-loki.yaml
```

⚠ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### 🗺️ Where are we in our scenario?

<!-- TODO: review the Mermaid diagram -->

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

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

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
