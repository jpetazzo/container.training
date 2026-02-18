# Install monitoring stack

The **_⚙️OPS_** team wants to have a real monitoring stack for its clusters.

- `Prometheus` and `Grafana` to collect and request metrics

- `Loki` to gather and search into the logs

---

## Reviewing our monitoring components in our Flux components catalog

You'll find in https://github.com/jpetazzo/k8s/flux/ a "catalog of components" ready to deploy with Flux.

Let's review 2  specific folders:

- kube-prometheus-stack
    - install Prometheus and Grafana _via_ Helm charts
    - install Grafana dashboards dedicated to Flux insights
    - configure an Ingress to publicly expose the Web interfaces

- loki
    - install Loki and Promtail _via_ Helm charts

Both are heavily inspired from [Flux2-monitoring example](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring)

---

### Flux CLI works locally

First, we have to **locally** clone your `Flux` configuration `Github` repository

- create an ssh key pair
- add the **public** key to your `Github` repository (**with write access**)
- and git clone the repository

⚠️ For Flux to take into account this configuration update you have to push your commits to Github.

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

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Results

.lab[

```bash
k8s@shpod:~/$ flux get all -A
NAMESPACE       NAME                                    REVISION                SUSPENDED       READY   MESSAGE
monitoring      ocirepository/kube-prometheus-stack     69.8.2@sha256:e104d0db  False           True    stored artifact for digest '69.8.2@sha256:e104d0db'

NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     gitrepository/catalog           main@sha1:d8ec150e      False           True    stored artifact for revision 'main@sha1:d8ec150e'
flux-system     gitrepository/flux-system       main@sha1:cc5a2e80      False           True    stored artifact for revision 'main@sha1:cc5a2e80'
monitoring      gitrepository/monitoring        main@sha1:82c37257      False           True    stored artifact for revision 'main@sha1:82c37257'

NAMESPACE       NAME                                    REVISION                SUSPENDED       READY   MESSAGE
monitoring      helmrelease/kube-prometheus-stack       69.8.2+e104d0db587d     False           Unknown Running 'install' action with timeout of 5m0s

NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     kustomization/flux-system       main@sha1:cc5a2e80      False           True    Applied revision: main@sha1:cc5a2e80
flux-system     kustomization/monitoring        main@sha1:d8ec150e      False           True    Applied revision: main@sha1:d8ec150e
monitoring      kustomization/dashboards                                False           False   PodMonitor/monitoring/flux-system dry-run failed: no matches for kind "PodMonitor" in version "monitoring.coreos.com/v1"

monitoring      kustomization/monitoring        main@sha1:82c37257      False           True    Applied revision:main@sha1:82c37257
```
]

---

class: extra-details

### Using external Git source

💡 Note that you can directly use public `Github` repository (not maintained by your company).

- If you have to alter the configuration, `Kustomize` patching capabilities might help.

- Depending on the _gitflow_ this repository uses, updates will be deployed automatically to your cluster (here we're using the `main` branch).

- This repo exposes a `kustomization.yaml`. Well done!

---

## Access the Grafana dashboard

.lab[

- Get the `Host` and `IP` address to request

```bash
k8s@shpod:~$ kubectl -n monitoring get ingress
NAME      CLASS   HOSTS                              ADDRESS  PORTS   AGE
grafana   traefik grafana.enix.thegaragebandofit.com          80, 443 6m30s
```

- Get the `Grafana` admin password

```bash
k8s@shpod:~$ k get secret kube-prometheus-stack-grafana -n monitoring \
                -o jsonpath='{.data.admin-password}' | base64 -d
```

]

⚠️ As of now, Ingress doesn't have public address. Something we have to work on!
Meanwhile, we can use `kubectl port-forward`… and browse!

---

class: pic

![Grafana dashboard screenshot](images/flux/grafana-dashboard.png)

---

## Adding Loki to our observability stack

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

- ⚠️ Don't forget to add this entry into the `kustomization.yaml` file

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Results


.lab[

```bash
k8s@shpod:~/$ k get pods -n monitoring
NAME                                                        READY   STATUS    RESTARTS   AGE
kube-prometheus-stack-grafana-6b97659f5b-w8w4b              3/3     Running   0          17m
kube-prometheus-stack-kube-state-metrics-86d5667ddb-g9htn   1/1     Running   0          17m
kube-prometheus-stack-operator-7d75f6495-rxjgl              1/1     Running   0          17m
kube-prometheus-stack-prometheus-node-exporter-2dj7l        1/1     Running   0          17m
kube-prometheus-stack-prometheus-node-exporter-gv672        1/1     Running   0          17m
loki-0                                                      1/2     Running   0          53s
loki-gateway-5d4c56c96f-vzwbv                               1/1     Running   0          53s
loki-minio-0                                                1/1     Running   0          53s
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          16m
promtail-brrq9                                              1/1     Running   0          53s
promtail-krhzj                                              1/1     Running   0          53s
```

]

---

class: pic

![Loki dashboard](images/flux/loki-dashboard.png)

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
