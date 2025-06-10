# T05- Configuring ingress for **_🎸ROCKY_** app

🍾 **_🎸ROCKY_** team has just deployed its `v1.0.0`

We would like to reach it from our workstations  
The regular way to do it in Kubernetes is to configure an `Ingress` resource.

- `Ingress` is an abstract resource that manages how services are exposed outside of the Kubernetes cluster (Layer 7).  
- It relies on `ingress-controller`(s) that are technical solutions to handle all the rules related to ingress.

- Available features vary, depending on the `ingress-controller`: load-balancing, networking, firewalling, API management, throttling, TLS encryption, etc.
- `ingress-controller` may provision Cloud _IaaS_ network resources such as load-balancer, persistent IPs, etc.

---

## 🔍 Ingress -- for more info

Please, refer to the [`Ingress` chapter in the High Five M2 module](./2.yml.html#toc-exposing-http-services-with-ingress-resources)

---

## Installing `ingress-nginx` as our `ingress-controller`

We'll use `ingress-nginx` (relying on `NGinX`), quite a popular choice.

- It is able to provision IaaS load-balancer in ScaleWay Cloud services
- As a reverse-proxy, it is able to balance HTTP connections on an on-premises cluster

**_⚙️OPS_** Team add this new install to its `Flux` config. repo

---

### Creating a `Github` source in Flux for `ingress-nginx`

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$             \
    mkdir -p ./clusters/CLOUDY/ingress-nginx &&        \
    flux create source git ingress-nginx               \
    --namespace=ingress-nginx                          \
    --url=https://github.com/kubernetes/ingress-nginx/ \
    --branch=release-1.12                              \
    --export > ./clusters/CLOUDY/ingress-nginx/sync.yaml
```

]

---

### Creating `kustomization` in Flux for `ingress-nginx`

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create kustomization ingress-nginx \
    --namespace=ingress-nginx                                                      \
    --source=GitRepository/ingress-nginx                                           \
    --path="./deploy/static/provider/scw/"                                         \
    --export >> ./clusters/CLOUDY/ingress-nginx/sync.yaml

k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cp -p ~/container.training/k8s/M6-ingress-nginx-kustomization.yaml    \
                    ./clusters/CLOUDY/ingress-nginx/kustomization.yaml && \
    cp -p ~/container.training/k8s/M6-ingress-nginx-components.yaml       \
          ~/container.training/k8s/M6-ingress-nginx-*-patch.yaml          \
                    ./clusters/CLOUDY/ingress-nginx/
```

]

---

### Applying the new config

.lab[

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    git add ./clusters/CLOUDY/ingress-nginx && \
    git commit -m':wrench: :rocket: add Ingress-controller' && \
    git push
```

]

---

class: pic

![Ingress-nginx provisionned a IaaS load-balancer in Scaleway Cloud services](images/M6-ingress-nginx-scaleway-lb.png)

---

class: extra-details

### Using external Git source

💡 Note that you can directly use pubilc `Github` repository (not maintained by your company).  

- If you have to alter the configuration, `Kustomize` patching capabilities might help.

- Depending on the _gitflow_ this repository uses, updates will be deployed automatically to your cluster (here we're using a `release` branch).

- This repo exposes a `kustomization.yaml`. Well done!

---

## Adding the `ingress` resource to ROCKY app

.lab[

- Add the new manifest to our kustomization bunch

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    cp -pr ~/container.training/k8s/M6-rocky-ingress.yaml ./tenants/base/rocky && \
    echo '- M6-rocky-ingress.yaml' >> ./tenants/base/rocky/kustomization.yaml
```

- Commit and its done

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ \
    git add . && \
    git commit -m':wrench: :rocket: add Ingress' && \
    git push
```

]

---

### Here is the result!

After Flux reconciled the whole bunch of sources and kustomizations, you should see

- `Ingress-NGinX` controller components in `ingress-nginx` namespace
- A new `Ingress` in `rocky-test` namespace

.lab[

```bash
k8s@shpod:~$ kubectl get all -n ingress-nginx && \
             kubectl get ingress -n rocky-test

k8s@shpod:~$ \
    PublicIP=$(kubectl get ingress rocky -n rocky-test \
                -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

k8s@shpod:~$ \
    curl --header 'rocky.test.mybestdomain.com' http://$PublicIP/
```

]

---

class: pic

![Rocky application screenshot](images/M6-rocky-app-screenshot.png)

---

## Upgrading **_🎸ROCKY_** app

**_🎸ROCKY_** team is now fully able to upgrade and deploy its app autonomously.

Just give it a try!
- In the `deployment.yaml` file
- in the app repo ([https://github.com/Musk8teers/container.training-spring-music/])
- you can change the `spec.template.spec.containers.image` to `1.0.1` and then to `1.0.2`

Dont' forget which branch is watched by `Flux` Git source named `rocky`

Don't forget to commit!

---

## Few considerations

- **_⚙️OPS_** team has to decide how to manage name resolution for public IPs
  - Scaleway propose to expose a wildcard domain for its Kubernetes clusters

- Here, we chose that `Ingress-controller` (that makes sense) but `Ingress` as well were managed by **_⚙️OPS_** team.
  - It might have been done in many different ways!

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
    commit id:'ROCKY config.' tag:'T03'
    commit id:'namespace isolation by RBAC'
    checkout TEST-env
    merge OPS id:'ROCKY tenant creation' tag:'T04'

    checkout OPS
    commit id:'ROCKY deploy. config.' tag:'R01'

    checkout TEST-env
    merge OPS id:'FLUX ready to deploy ROCKY' type: HIGHLIGHT tag:'R02'

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

<<<<<<< HEAD
    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'

=======
>>>>>>> a0dc6a2d (📝 Add Ingress chapter)
    checkout ROCKY
    commit id:'blue color' tag:'v1.0.1'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.1'

    checkout ROCKY
    commit id:'pink color' tag:'v1.0.2'
    checkout TEST-env
    merge ROCKY tag:'ROCKY v1.0.2'
<<<<<<< HEAD
=======

    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'
>>>>>>> a0dc6a2d (📝 Add Ingress chapter)
</pre>
