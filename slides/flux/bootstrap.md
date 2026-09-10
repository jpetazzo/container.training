# Creating **_⚗️TEST_** env on our **_☁️CLOUDY_** cluster

Let's take a look at our **_☁️CLOUDY_** cluster!

**_☁️CLOUDY_** is a Kubernetes cluster created with [Scaleway Kapsule](https://www.scaleway.com/en/kubernetes-kapsule/) managed service

This managed cluster comes preinstalled with specific features:
- Kubernetes dashboard
- specific _Storage Classes_ based on Scaleway _IaaS_ block storage offerings
- a `Cilium` _CNI_ stack already set up

---

## Accessing the managed Kubernetes cluster

To access our cluster, we'll connect via [`shpod`](https://github.com/jpetazzo/shpod)

.lab[

- If you already have a kubectl on your desktop computer
```bash
kubectl -n shpod run shpod --image=jpetazzo/shpod
kubectl -n shpod exec -it shpod -- bash
```
- or directly via ssh
```bash
ssh -p myPort k8s@mySHPODSvcIpAddress
```

]

---

## Flux installation

Once `Flux` is installed,  
the **_⚙️OPS_** team exclusively operates its clusters by updating a code base in a `Github` repository

_GitOps_ and `Flux` enable the **_⚙️OPS_** team to rely on the _first-class citizen pattern_ in Kubernetes' world through these steps:

- describe the **desired target state**
- and let the **automated convergence** happen

---

### Checking prerequisites

The `Flux` _CLI_ is available in our `shpod` pod

Before installation, we need to check that:
   - `Flux` _CLI_ is correctly installed
   - it can connect to the `API server`
   - our versions of `Flux` and Kubernetes are compatible

.lab[

```bash
k8s@shpod:~$ flux --version
flux version 2.7.5

k8s@shpod:~$ flux check --pre
► checking prerequisites
✔ Kubernetes 1.35.1 >=1.32.0-0
✔ prerequisites checks passed
```

]

---

### Git repository for Flux configuration

The **_⚙️OPS_** team uses `Flux` _CLI_
- to create a `git` repository named `fleet-config-using-flux-XXXXX` (⚠ replace `XXXXX` by a personnal suffix)
- in our `Github` organization named `container-training-fleet`

Prerequisites are:
  - `Flux` _CLI_ needs a `Github` personal access token (_PAT_)
      - to create and/or access the `Github` repository
      - to give permissions to existing teams in our `Github` organization
  - The _PAT_ needs _CRUD_ permissions on our `Github` organization
    - repositories

- As **_⚙️OPS_** team, let's creates a `Github` personal access token…

---

class: pic

![Generating a Github personal access token](images/flux/github-add-token.jpg)

---

### Creating dedicated `Github` repo to host Flux config

.lab[
- let's replace the `GITHUB_TOKEN` value by our _Personal Access Token_
- and the `GITHUB_REPO` value by our specific repository name

```bash
k8s@shpod:~$ export GITHUB_TOKEN="my-token" &&         \
      export GITHUB_USER="container-training-fleet" && \
      export GITHUB_REPO="fleet-config-using-flux-XXXXX"

k8s@shpod:~$ flux bootstrap github \
      --owner=${GITHUB_USER}       \
      --repository=${GITHUB_REPO}  \
      --team=OPS                   \
      --team=STORAGE-ADMINS        \
      --team=NETWORK-ADMINS        \
      --path=clusters/CLOUDY
```
]

---

class: extra-details

### Creating a personnal dedicated `Github` repo

You don't need to rely onto a Github organization: any `Github` personnal repository is OK.

.lab[

- let's replace the `GITHUB_TOKEN` value by our _Personal Access Token_
- and the `GITHUB_REPO` value by our specific repository name

```bash
k8s@shpod:~$ export GITHUB_TOKEN="my-token" &&         \
      export GITHUB_USER="lpiot" && \
      export GITHUB_REPO="fleet-config-using-flux-XXXXX"

k8s@shpod:~$ flux bootstrap github \
      --owner=${GITHUB_USER}       \
      --personal                   \
      --repository=${GITHUB_REPO}  \
      --path=clusters/CLOUDY
```
]

---

class: extra-details

Here is the result

```bash
✔ repository "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX" created                                                                                                                                                        
► reconciling repository permissions
✔ granted "maintain" permissions to "OPS"
✔ granted "maintain" permissions to "STORAGE-ADMINS"
✔ granted "maintain" permissions to "NETWORK-ADMINS"
► reconciling repository permissions
✔ reconciled repository permissions
► cloning branch "main" from Git repository "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed component manifests to "main" ("7c97bdeb5b932040fd8d8a65fe1dc84c66664cbf")
► pushing component manifests to "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX.git"
✔ component manifests are up to date
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBFqaT8B8SezU92qoE+bhnv9xONv9oIGuy7yVAznAZfyoWWEVkgP2dYDye5lMbgl6MorG/yjfkyo75ETieAE49/m9D2xvL4esnSx9zsOLdnfS9W99XSfFpC2n6soL+Exodw==
✔ configured deploy key "flux-system-main-flux-system-./clusters/CLOUDY" for "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("11035e19cabd9fd2c7c94f6e93707f22d69a5ff2")
► pushing sync manifests to "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX.git"
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for GitRepository "flux-system/flux-system" to be reconciled
✔ GitRepository reconciled successfully
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
✔ Kustomization reconciled successfully
► confirming components are healthy
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```

---

### Flux configures Github repository access for teams

- `Flux` sets up permissions that allow teams within our organization to **access** the `Github` repository as maintainers
- Teams need to exist before `Flux` proceeds to this configuration

![Teams in Github](images/flux/github-teams.png)

---

### ⚠️ Disclaimer

- In this lab, adding these teams as maintainers was merely a demonstration of how `Flux` _CLI_ sets up permissions in Github

- But there is no need for dev teams to have access to this `Github` repository

- One advantage of _GitOps_ lies in its ability to easily set up 💪🏼 **Separation of concerns** by using multiple `Flux` sources

---

### The PAT is not needed anymore!

- During the install process, `Flux` creates an `ssh` key pair so that it is able to contribute to the `Github` repository.

```bash
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBFqaT8B8SezU92qoE+bhnv9xONv9oIGuy7yVAznAZfyoWWEVkgP2dYDye5lMbgl6MorG/yjfkyo75ETieAE49/m9D2xvL4esnSx9zsOLdnfS9W99XSfFpC2n6soL+Exodw==
✔ configured deploy key "flux-system-main-flux-system-./clusters/CLOUDY" for "https://github.com/container-training-fleet/fleet-config-using-flux-XXXXX"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
```

- You can now delete the formerly created _Personal Access Token_: `Flux` won't use it anymore.

---

### 📂 Flux config files

`Flux` has been successfully installed onto our **_☁️CLOUDY_** Kubernetes cluster!

Its configuration is managed through a _Gitops_ workflow sourced directly from our `Github` repository

Let's review our `Flux` configuration files we've created and pushed into the `Github` repository…  
… as well as the corresponding components running in our Kubernetes cluster

![Flux config files](images/flux/flux-config-files.png)

---

class: pic

![Flux architecture](images/flux/flux-controllers.png)

---

class: extra-details

### Flux resources 1/2

.lab[

```bash
k8s@shpod:~$ kubectl get all --namespace flux-system
NAME                                           READY   STATUS    RESTARTS   AGE
pod/helm-controller-b6767d66-h6qhk             1/1     Running   0          5m
pod/kustomize-controller-57c7ff5596-94rnd      1/1     Running   0          5m
pod/notification-controller-58ffd586f7-zxfvk   1/1     Running   0          5m
pod/source-controller-6ff87cb475-g6gn6         1/1     Running   0          5m

NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/notification-controller   ClusterIP   10.104.139.156   <none>        80/TCP    5m1s
service/source-controller         ClusterIP   10.106.120.137   <none>        80/TCP    5m
service/webhook-receiver          ClusterIP   10.96.28.236     <none>        80/TCP    5m
(…)
```

]

---

class: extra-details

### Flux resources 2/2

.lab[

```bash
k8s@shpod:~$ kubectl get all --namespace flux-system
(…)
NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/helm-controller           1/1     1            1           5m
deployment.apps/kustomize-controller      1/1     1            1           5m
deployment.apps/notification-controller   1/1     1            1           5m
deployment.apps/source-controller         1/1     1            1           5m

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/helm-controller-b6767d66             1         1         1       5m
replicaset.apps/kustomize-controller-57c7ff5596      1         1         1       5m
replicaset.apps/notification-controller-58ffd586f7   1         1         1       5m
replicaset.apps/source-controller-6ff87cb475         1         1         1       5m
```

]

---

### Flux components

- the `source controller` monitors `Git` repositories to apply Kubernetes resources on the cluster

- the `Helm controller` checks for new `Helm` _charts_ releases in `Helm` repositories and installs updates as needed

- _CRDs_ store `Flux` configuration within the Kubernetes control plane

---

class: extra-details

### Flux resources that have been created

.lab[

```bash
k8s@shpod:~$ flux get all --all-namespaces
NAMESPACE       NAME                            REVISION                SUSPENDED
      READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:d48291a8      False
      True    stored artifact for revision 'main@sha1:d48291a8'

NAMESPACE       NAME                            REVISION                SUSPENDED
      READY   MESSAGE
flux-system     kustomization/flux-system       main@sha1:d48291a8      False
      True    Applied revision: main@sha1:d48291a8
```

]

---

### Flux CLI

`Flux` Command-Line Interface fulfills 3 primary functions:

1. It installs and configures first mandatory `Flux` resources in a _Gitops_ `git` repository
  - ensuring proper access and permissions

2. It locally generates `YAML` files for desired `Flux` resources so that we just need to `git push` them
  - _tenants_
  - sources
  - …

3. It requests the API server to manage `Flux`-related resources
     - _operators_
     - _CRDs_
     - logs

---

class: extra-details

### Flux -- for more info

Please, refer to the [`Flux` chapter in the High Five M3 module](./3.yml.html#toc-helm-chart-format)

---

### Flux relies on Kustomize

The `Flux` component named `kustomize controller` look for `Kustomize` resources in `Flux` code-based sources

1. `Kustomize` look for `YAML` manifests listed in the `kustomization.yaml` file

2. and aggregates, hydrates and patches them following the `kustomization` configuration

---

class: extra-details

### 2 different kustomization resources

⚠️ `Flux` uses 2 distinct resources with `kind: kustomization`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: kustomization
```

describes how Kustomize (the _CLI_ tool) appends and transforms `YAML` manifests into a single bunch of `YAML` described resources

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1 group
kind: Kustomization
```

describes where `Flux kustomize-controller` looks for a `kustomization.yaml` file in a given `Flux` code-based source

---

class: extra-details

### Kustomize -- for more info

Please, refer to the [`Kustomize` chapter in the High Five M3 module](./3.yml.html#toc-kustomize)

---

class: extra-details

### Group / Version / Kind -- for more info

For more info about how Kubernetes resource natures are identified by their `Group / Version / Kind` triplet…  
… please, refer to the [`Kubernetes API` chapter in the High Five M5 module](./5.yml.html#toc-the-kubernetes-api)

---

### 💡 A standard components catalog : the power of Kustomization

Flux Kustomization resource is made to target remote pieces of installation and configuration

We will create a folder with primitives to deploy any component…

… and Kustomizations into the folder where our cluster install is configured

- to target every components we want to deploy

![Flux components catalog](images/flux/flux-components-catalog.png)

---

## Creating `Github` source in Flux for components catalog repository

.lab[

- Let's create the `Flux` Source to target our component catalog

```bash
k8s@shpod:~/fleet-config-using-flux-XXXXX$ mkdir -p clusters/CLOUDY/install-components

k8s@shpod:~/fleet-config-using-flux-XXXXX$ flux create source git catalog       \
    --namespace=flux-system                                                     \
    --url=https://github.com/container-training-fleet/componentcatalog4flux.git \
    --branch=main  --export > ./clusters/CLOUDY/install-components/sync.yaml

k8s@shpod:~/fleet-config-using-flux-XXXXX$     \
    cd ./clusters/CLOUDY/install-components && \
    kustomize create --autodetect &&           \
    cd -

- and commit & push
```
]

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
    checkout YouRHere
    commit id:'x'
    checkout OPS
    merge YouRHere id:'YOU ARE HERE'
</pre>
