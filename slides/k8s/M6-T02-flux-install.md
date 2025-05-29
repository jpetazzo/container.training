# T02- **_⚗️TEST_** env creation (on **_☁️CLOUDY_** cluster )

Let's take a look to our cloudy cluster!  

<!-- TODO: few commands to see what our cluster offers -->
<!-- TODO: démarrer shpod avec un serviceaccount qui va bien pour attaquer l'API server
### Run inside an shpod


```
kubectl run shpod --image=jpetazzo/shpod --overrides='{ "spec": { "serviceAccountName": "" } }'
```
 -->

---

## Flux install

Once `Flux` is installed,  
**_⚙️OPS_** team exclusively operates its clusters by updating a code base in a `git` repository  

_GitOps_ and `Flux` enable **_⚙️OPS_** team to rely on the _first-citizen pattern_ in Kubernetes world:

- describe the desired target state
- and let the automated convergence happens.

---

### Checking prerequisites

`Flux` _CLI_ is available in your `shpod` pod

First, we check:
   - that `Flux` _CLI_ is right there and run correctly
   - that it is able to connect to the `API server`
   - that both `Flux` and `Kubernetes` are OK and work well together

.lab [

```bash
shpod:~# flux --version
flux version 2.5.1

shpod:~# flux check --pre
► checking prerequisites
✔ Kubernetes 1.32.3 >=1.30.0-0
✔ prerequisites checks passed
```

]

---

### Git repository to store the Flux configuration of our clusters

- **_⚙️OPS_** uses the _CLI_
  - to create a `fleet-config-using-flux-XXX` repository
  - in our `Github` organization : `container-training-fleet`

- To do so, `Flux` _CLI_ needs
  - a `Github` _PAT_ (personal access token)
  - with _CRUD_ permissions on our `Github` organization repositories

- So, **_⚙️OPS_** team creates a `Github` personal access token

---

### Generate a Github Personal Access Token (PAT)

![Generate a Github personal access token](images/M6-github-add-token.png)

---

### Creating dedicated `Github` repo to host Flux config

- replace the `GITHUB_TOKEN` value by your _Personal Access Token_
- replace the `GITHUB_REPO` value by your specific repository name
 
.lab [

```bash
$ export GITHUB_TOKEN="my-token"
$ export GITHUB_USER="container-training-fleet"
$ export GITHUB_REPO="fleet-config-using-flux-XXXXX"

$ flux bootstrap github         \
    --owner=${GITHUB_USER}      \
    --repository=${GITHUB_REPO} \
    --team=OPS                  \
    --team=ROCKY                \
    --team=MOVY                 \
    --path=clusters/CLOUDY
```

]

---

Here is the result of the command

```bash
✔ repository "https://github.com/container-training-fleet/fleet-config-using-flux-lpiot" created                                                                                                                                                        
► reconciling repository permissions
✔ granted "maintain" permissions to "OPS"
✔ granted "maintain" permissions to "ROCKY"
✔ granted "maintain" permissions to "MOVY"
► reconciling repository permissions
✔ reconciled repository permissions
► cloning branch "main" from Git repository "https://github.com/container-training-fleet/fleet-config-using-flux-lpiot.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed component manifests to "main" ("7c97bdeb5b932040fd8d8a65fe1dc84c66664cbf")
► pushing component manifests to "https://github.com/container-training-fleet/fleet-config-using-flux-lpiot.git"
✔ component manifests are up to date
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBFqaT8B8SezU92qoE+bhnv9xONv9oIGuy7yVAznAZfyoWWEVkgP2dYDye5lMbgl6MorG/yjfkyo75ETieAE49/m9D2xvL4esnSx9zsOLdnfS9W99XSfFpC2n6soL+Exodw==
✔ configured deploy key "flux-system-main-flux-system-./clusters/CLOUDY" for "https://github.com/container-training-fleet/fleet-config-using-flux-lpiot"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("11035e19cabd9fd2c7c94f6e93707f22d69a5ff2")
► pushing sync manifests to "https://github.com/container-training-fleet/fleet-config-using-flux-lpiot.git"
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

### Flux configures Github repository permissions for organization teams

- `Flux` configures permissions for organization teams to **maintain** the `Github` repository
- Teams should already exist before `Flux` configuration

![Teams in Github](images/M6-github-teams.png)

---

### ⚠️ Disclaimer

- In this lab, adding these teams as maintainers was just a way to demonstrate how `Flux` _CLI_ configures permissions in Github  

- We don't need for dev teams to have access to this `Github` repository  

- 💪🏼 **Separation of concerns** by using multiple `Flux` sources is one of the advantages of _GitOps_

---

### 📂 Flux config files

`Flux` is now installed onto our cloudy cluster!  

And it's configuration is now maintained _via_ a _Gitops_ workflow sourcing in the `git` repository

Let's review the config files `Flux` created and commited into the `git` repository…
… and the actual components in our cluster

![Flux config files](images/M6-flux-config-files.png)

---

### Flux architecture

![Flux architecture](images/M6-flux-schema.png)

---

### Flux components

- `source controller` watches sources based upon `git` repositories to apply the `Kubernetes` resources it finds on the cluster

- `helm controller` look for new `Helm` _charts_ releases in `Helm` _charts_ repositories to install them on the cluster

- _CRDs_ store `Flux` configuration in `Kubernetes` control plane

---

### Flux CLI

`Flux` _CLI_ has 3 main roles :

1. to install and configure initial `Flux` resources into a _Gitops_-oriented `git` repository
  - it configures this repository (permissions, keys to access it…)

1. to locally create the `YAML` files for any `Flux` resources we wish to add to our `Flux` _Gitops_ configuration
  - tenants
  - sources
  - …

1. to request the API server for `Flux`-related resources
     - _operators_
     - _CRDs_
     - logs

---

### 🔍 Flux -- for more info

Look at the `Flux` [chapter in High Five M3 module](./3.yml.html#toc-helm-chart-format)

---

### Flux relies on Kustomize

The `Flux` component named `kustomize controller` look for `Kustomize` resources in sources

1. `Kustomize` look for the `YAML` manifests listed in the `kustomization`

2. and aggregates, hydrates and patches them following the `kustomization` configuration

---

### 🔍 Kustomize -- for more info

Look at the [`Kustomize` chapter in High Five M3 module](./3.yml.html#toc-kustomize)

---
