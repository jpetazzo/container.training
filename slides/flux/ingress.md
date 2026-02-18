# Configuring Ingresses

Our observability stack already exposes 2 URLs.  
But we can't reach them from our workstations.

The regular way to do it in Kubernetes is to configure an `Ingress` resource.

- `Ingress` is an abstract resource that manages how services are exposed outside of the Kubernetes cluster (Layer 7).  
- It relies on `ingress-controller`(s) that are technical solutions to handle all the rules related to ingress.

- Available features vary, depending on the `ingress-controller`: load-balancing, networking, firewalling, API management, throttling, TLS encryption, etc.
- `ingress-controller` may provision Cloud _IaaS_ network resources such as load-balancer, persistent IPs, etc.

---

class: extra-details

## Ingress -- for more info

Please, refer to the [`Ingress` chapter in the High Five M2 module](./2.yml.html#toc-exposing-http-services-with-ingress-resources)

---

## Installing `traefik` as our `ingress-controller`

- Formerly, we used to install `ingress-nginx` (relying on `NGinX`), quite a popular choice.
  - But it's end-of-support, we'll install `Traefik` as a replacement.

- `Traefik Proxy` is a full-featured ingress-controller 
  - It is able to provision IaaS load-balancer in ScaleWay Cloud services
  - As a reverse-proxy, it is able to balance HTTP connections on an on-premises cluster
  - and so much more!

The **_⚙️OPS_** Team add this new component to its `Flux` config. repo

---

### Creating a Kustomization in Flux for `ingress-nginx`

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization traefik \
    --namespace=flux-system                                                  \
    --source=GitRepository/catalog                                           \
    --path="./k8s/flux/traefik/"                                             \
    --export >> ./clusters/CLOUDY/install-components/sync-traefik.yaml

⚠ Don't forget to add this entry into the `kustomization.yaml` file
… And to commit/push to Github!
```

]

---

class: pic

![Running Mario](images/running-mario.gif)

---

### Result

.lab[

```bash
k8s@shpod:~/$ flux get all -n traefik
NAME                    REVISION        SUSPENDED       READY   MESSAGE                                     
helmrepository/traefik  sha256:92b5b547 False           True    stored artifact: revision 'sha256:92b5b547'

NAME                            REVISION        SUSPENDED       READY   MESSAGE                                      
helmchart/traefik-traefik       37.2.0          False           True    pulled 'traefik' chart with version '37.2.0'

NAME                    REVISION        SUSPENDED       READY   MESSAGE                                                                         
helmrelease/traefik     37.2.0          False           True    Helm install succeeded for release traefik/traefik.v1 with chart traefik@37.2.0
```

]

---

### Interacting with the IaaS platform

When deploying `Traefik` ingress-controller in Scaleway Cloud platform, Iaas resources are created:

- a "physical" load-balancer
- public IPs (IPv4 and IPv6)

---

class: pic

![Ingress-nginx provisionned a IaaS load-balancer in Scaleway Cloud services](images/flux/ingress-nginx-scaleway-lb.png)

---

## 📂 Let's review the files

- `namespace.yaml`
  </br>To include the `Flux` resources in the same _namespace_ where `Flux` installs the `traefik` resources, we need to create the _namespace_ **before** the installation occurs

- `sync.yaml`
  </br>The resources `Flux` uses to watch and get the `Helm chart`
  
- `values.yaml`
  </br> The `values.yaml` file that will be injected into the `Helm chart`

- `kustomization.yaml`
  </br>This one is a bit special: it includes a [ConfigMap generator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/)

- `kustomize-config.yaml`
  </br>⚠️This one is tricky: in order for `Flux` to trigger an upgrade of the `Helm Release` when the `ConfigMap` is altered, you need to explain to the `Kustomize ConfigMap generator` how the resources are relating with each others. 🤯 
 
And here we go!

---

### Here is the result

After Flux reconciled the whole bunch of sources and kustomizations, you should see

- `Traefik` controller components in `traefik` namespace
- The monitoring `Ingress` in `monitoring` namespace should have been updated with public IP

.lab[

```bash
k8s@shpod:~$ kubectl get all -n traefik && \
             kubectl get ingress --all-namespaces

k8s@shpod:~$ \
    PublicIP=$(kubectl get ingress monitoring -n monitoring \
                -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

k8s@shpod:~$ \
    curl --header 'grafana.enix.thegaragebandofit.com' http://$PublicIP/
```

]

---

class: pic

![Grafana dashboard screenshot](images/flux/grafana-dashboard.png)

---

## Few considerations

- The **_⚙️OPS_** team has to decide how to manage name resolution for public IPs
  - Scaleway propose to expose a wildcard domain for its Kubernetes clusters

- Here, we chose that `Ingress-controller` (that makes sense) but `Ingress` as well were managed by the **_⚙️OPS_** team.
  - It might have been done in many different ways!

---

<!-- TODO: add cert-manager install -->

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

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

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
