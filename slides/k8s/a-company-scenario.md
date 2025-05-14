# Using Kubernetes in an Enterprise-like scenario

- 💪🏼 Okay. The former training modules explain each subject in-depth, and each feature one at-a-time

- 🤯 One of the first complexity any `k8s` admin encounters resides in having to choose and assemble all these moving parts to build a _Production-ready_ `k8s` cluster

- 🎯 This module precisely aims to play a classic corporate scenario and see what we'll have to do to build such a Prod-ready Kubernetes cluster

- As we've done it before, we'll start to build our cluster from scratch and improve it step by step, by adding a feature one after another

---

## The plan

In a company, we have 3 different people, _**⚙️OPS**_, _**🎸ROCKY**_ and _**🎻CLASSY**_

- _**⚙️OPS**_ is the platform engineer building and configuring Kubernetes clusters

- Both _**🎸ROCKY**_ and _**🎻CLASSY**_ build Web apps that manage 💿 record collections

    - _**🎸ROCKY**_ builds a Web app managing _rock & pop_ collection
    - whereas _**🎻CLASSY**_ builds a Web app for _classical_ collection

- Each app is stored in its own git repository

- Both _**🎸ROCKY**_ and _**🎻CLASSY**_ want to code, build package and deploy their applications onto a `Kubernetes` _cluster_ _in an autonomous way_

---

### What our scenario might look like…

<pre class="mermaid">
%%{init:
    {
      "theme": "default",
      "gitGraph": {
        "mainBranchName": "ops",
        "mainBranchOrder": 0
      }
    }
}%%
gitGraph
    commit id:"0" tag:"start"
    branch ROCKY order:3
    branch CLASSY order:4

    checkout ops
    commit id:'TEST cluster creation' tag:'T01'
    branch TEST-cluster order:1
    commit id:'FLUX install on TEST' tag:'T02'

    checkout ops
    commit id:'TEST cluster config.' tag:'T03'
    checkout TEST-cluster
    merge ops id:'setup of TEST cluster' tag:'T04'

    checkout ops
    commit id:'FLUX config for ROCKY deployment' tag:'R01'

    checkout TEST-cluster
    merge ops id:'FLUX ready to deploy ROCKY' type: HIGHLIGHT tag:'R02'

    checkout ROCKY
    commit id:'ROCKY' tag:'v1.0'

    checkout TEST-cluster
    merge ROCKY tag:'ROCKY v1.0'
    
    checkout CLASSY
    commit id:'CLASSY' tag:'v1.0'

    checkout CLASSY
    commit id:'CLASSY HELM chart' tag:'C01'

    checkout ops
    commit id:'FLUX config for CLASSY deployment' tag:'C02'
    checkout TEST-cluster
    merge ops id:'FLUX ready to deploy CLASSY' type: HIGHLIGHT tag:'C03'

    checkout TEST-cluster
    merge CLASSY tag:'CLASSY v1.0'
    
    checkout ROCKY
    commit id:'new color' tag:'v1.1'
    checkout TEST-cluster
    merge ROCKY tag:'ROCKY v1.1'

    checkout TEST-cluster
    commit id:'wrong namespace' type: REVERSE

    checkout ops
    commit id:'namespace isolation'
    checkout TEST-cluster
    merge ops type: HIGHLIGHT

    checkout ROCKY
    commit id:'fix namespace' tag:'v1.1.1'
    checkout TEST-cluster
    merge ROCKY tag:'ROCKY v1.1.1'

    checkout ROCKY
    commit id:'add a field' tag:'v1.2'
    checkout TEST-cluster
    merge ROCKY tag:'ROCKY v1.2'

    checkout ops
    commit id:'Kyverno install'
    commit id:'Kyverno rules'
    checkout TEST-cluster
    merge ops type: HIGHLIGHT

    checkout ops
    commit id:'Network policies'
    checkout TEST-cluster
    merge ops type: HIGHLIGHT

    checkout ops
    branch PROD-cluster order:2
    commit id:'FLUX install on PROD'
    commit id:'_**🚜PROD**_ cluster configuration'

    checkout ops
    commit id:'Add OpenEBS'
    checkout TEST-cluster
    merge ops id:'patch dedicated to PROD' type: REVERSE
    checkout PROD-cluster
    merge ops type: HIGHLIGHT
</pre>

---

### Using two Kubernetes clusters
<!-- TODO: choose how to deploy k8s cluster -->

We want to have 2 main `Kubernetes` clusters, one for **testing** and one for **production**

- we should use tools to **industrialise creation** of both clusters

- each cluster has it's **own lifecycle** (the addition or configuration of extra components/features may be done on one cluster and not the other)
- yet, configurations of these clusters must be as centralized as possible (to avoid inconsistency and to limit configuration code expansion and maintainance)

> 💻 we'll use `Flux` to configure and deploy new resources onto the clusters

---

### Multi-tenancy

Both _**🎸ROCKY**_ and _**🎻CLASSY**_ should use a **dedicated _"tenant"_** on each cluster

- _**🎸ROCKY**_ should be able to deploy, upgrade and configure its own app in its dedicated **namespace** without anybody else involved

- and the same for _**🎻CLASSY**_

- neither conflict nor collision should be allowed between the 2 apps or the 2 teams.

---

### How to create the _**⚗️TEST**_ cluster

🚧 First we have to create a _**⚗️TEST**_ cluster
- on-premise (Linux machine)
- single node
- no HA
- very easy to deploy / trash / recreate
- for the dev teams to deploy and test their apps
- for the **ops** team to test their new configurations and tools

<!-- FIXME: find some kind of emphatic style -->
> 💻 we'll use `k0s` to deploy it

---

### How to create the _**🚜PROD**_ cluster

🚧 Second, we will create a _**🚜PROD**_ cluster
- in the Cloud for availability and scalability purpose (let's say DigitalOcean)
- 3 nodes
- HA

> 💻 we'll use `clusterAPI` from our _**⚗️TEST**_ cluster to deploy it

---

### 1st development team  _**🎸ROCKY**_

Our first development team is developping an app to manage **rock & pop** music records.

Here is a what it looks like :

<!-- TODO: include screenshot -->

---

### The code

Here is the code…

<!-- TODO: include screenshot -->

---

### How to deploy?

- The app is to be deployed on Kubernetes cluster, in a dedicated `rocky` namespace.  
- So the _**🎸ROCKY**_ team produces a YAML file to deploy the whole needed Kubernetes resources to run this application.

<!-- TODO: move into the step-by-step part -->

.lab[

- Review the deployment manifest:
  ```bash
  cd apps/rocky/
  cat ./deployment.yaml
  ```

]

Then, the _**🎸ROCKY**_ team will have to apply its deployment using this command  

```bash
kubectl apply -f ./deployment.yaml
```

---

### Deploying in an autonomous way…


To do so, the _**🎸ROCKY**_ team requires

- ⚠️ a **network connection** between its workstation (where `kubectl` is executed) and both Kubernetes clusters

- ⚠️ an enabled **account** to operate onto the Kubernetes clusters

- ⚠️ an always _up-to-date_ `kubectl` config with **valid credentials**

- ⚠️ a `kubectl` CLI in a version compatible with both Kubernetes clusters

- 🔒 if this command is executed by a _CI/CD pipeline_, it will need the same requirements

💡 There might be a better way. With GitOps! 🍾

---

# Incoming Flux

💡 We'll use `Flux` so that deployments will be directly executed from inside the Kubernetes clusters.

- The _**⚙️OPS**_ team will proceed to configure GitOps

  - to configure the Kubernetes clusters

  - for the _**🎸ROCKY**_ team, `Flux` will check the app source code Github repository and deploy every time the right git event is triggered

  - for the _**🎻CLASSY**_ team, `Flux` will check every time a new Helm Chart release is published in the Helm Charts repository storing the app

---

## Configuring Flux for _**🎸ROCKY**_ team

What the _**⚙️OPS**_ team has to do:

- 🔧 Create a dedicated `rocky` _tenant_ on _**⚗️TEST**_ cluster
- 🔧 Create the `Flux` Github source pointing to the _**rocky**_ app source code repository
- 🔧 Add a `kustomize` patch into the global `Flux` config to include the `Flux` configuration for the _**rocky**_ app

What the _**🎸ROCKY**_ team has to do:

- 👨‍💻 Creating the `kustomize` file in the _**🎸ROCKY**_ app source code repository in Github.

---

## Creating the dedicated `rocky` tenant

- Using the `flux` _CLI_, we create the file configuring the tenant for the _**🎸ROCKY**_ team
- This is done in the global mutualized `base` configuration for both Kubernetes clusters

.lab[

- Review the deployment manifest:
  ```bash
  
$ mkdir -p ./tenants/base/rocky
$ flux create tenant rocky            \
    --with-namespace=rocky-ns         \
    --cluster-role=rocky-full-access  \
    --export > ./tenants/base/rocky/rbac.yaml  ```

]

---

<!-- Here begins the step-by-step part -->
# T01- _**⚗️TEST**_ cluster creation

On a Linux server, we do install a single node `k0s` cluster.

---

## _**⚗️TEST**_ cluster - How to configure?

We want to configure our _**⚗️TEST**_ cluster in a *-as-code and reusable way
➡️ `Flux`

---

## Flux - what is it?

- Flux est un outil qui permet de faire du GitOps sur Kubernetes
- Il scrute des sources qui vont servir à injecter des descriptions de ressources dans Kubernetes

---

### Flux CLI

- une CLI permet :
  1. de créer les fichiers `YAML` pour déployer les ressources `Kubernetes` que l'on souhaite
     - y compris les propres composants `Flux`
  1. d'interagir avec le dépôt `git` qui va servir de configuration `Flux`
  1. d'interroger l'état de Flux sur le _cluster_
     - logs des _operators_
     - _CRD_

---

### Flux architecture

![Flux architecture](images/flux_schema.jpg)

---

### Flux components

- `source controller` pour scruter les sources de configuration depuis des dépôts `git`
- `helm controller` pour détecter de nouvelles _releases_ depuis des dépôts de _charts_ `Helm`
- des _CRD_, qui servent de machine à état pour stocker la configuration dans le _cluster_

---

### Flux -- for more info

Reference to the `Flux` chapter in High Five M3 module

---

### Flux relies on Kustomize

- `kustomize controller` qui passe la configuration trouvée à `Kustomize`
    1. `Kustomize` consolide la configuration trouvée
    2. et hydrate les sections template présentes dans la configuration

---

### Kustomize -- for more info

Reference to the `Kustomize` chapter in High Five M3 module

---

## T02- _**⚗️TEST**_ cluster - Installing Flux

À partir de là, toute la configuration du _cluster_ Kubernetes peut se faire exclusivement en manipulant des dépôts `git`.

On est dans le respect du _pattern_ roi dans `Kubernetes` : **la convergence vers un état cible décrit**

---

### Flux CLI 1

1. L'équipe **ops** récupère la _CLI_ `Flux` sur son poste de travail
1. La _CLI_ va s'appuyer sur la configuration `kubectl` pour interagir avec le _cluster_
   - connectivité réseau
   - droits _RBAC_

----

### Flux install - Checking prerequisites

1. On s'assure que
   - la CLI se connecte bien
   - que les versions de `Flux` et de `Kubernetes` sont OK

```bash
$ flux check ---pre
► checking prerequisites
✔ Kubernetes 1.21.9-gke.1002 >=1.20.6-0
✔ prerequisites checks passed
```

----

### Git repo to host Flux configuration

- La CLI va créer un dépôt `fleet-infra` dans notre organisation `Github` : `one-kubernetes`
- Elle a besoin d'un _token_ `Github` capable de _CRUD_ sur les dépôts.

----

### Github - Generate a personnal access token

![Generate a Github personnal access token](images/github_add_token.png)

----

### Github configuration by Flux

- `Flux` peut aussi indiquer les équipes qui auront le droit de modifier cette configuration.
- Il faut que ces équipes fassent déjà partie de l'organisation.

![Teams in Github](images/github_teams.jpg)

----

### Disclaimer

- ⚠️ Ici on vous montre pour l'exemple, mais dans le reste du _workshop_ (comme dans la vraie vie) les différentes équipes n'ont pas besoin d'accéder à ce dépôt.

- C'est tout l'avantage des sources de configuration multiples.

----

### T03- Creating dedicated `Github` repo to host Flux config

```bash [1-3|5-10]
$ export GITHUB_TOKEN="<insert your Github personal token here>"
$ export GITHUB_USER="one-kubernetes"
$ export GITHUB_REPO="fleet-infra"

$ flux bootstrap github         \
    --owner=${GITHUB_USER}      \
    --repository=${GITHUB_REPO} \
    --team=rocky                 \
    --team=classy                 \
    --path=clusters/mycluster

► connecting to github.com
✔ repository "https://github.com/one-kubernetes/fleet-infra" created
► reconciling repository permissions
✔ granted "maintain" permissions to "rocky"
✔ granted "maintain" permissions to "classy"
✔ reconciled repository permissions
► cloning branch "main" from Git repository "https://github.com/one-kubernetes/fleet-infra.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed sync manifests to "main" ("b4906bb66eca7296ba28f0c83808d6de143f930f")
► pushing component manifests to "https://github.com/one-kubernetes/fleet-infra.git"
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBPWKYVtQ6aCxQMMGRt+HqYD/JRC4sSQtdacQNMs+qhoppVH2+kNMnWIEl8LpJO1szfM2/d+gu3O1bg4T+WkEHgmepO1AYDpO8zmR3uMgeRg7IPeZY3E2BgVaKvfdRuDs6g==
✔ configured deploy key "flux-system-main-flux-system-./clusters/mycluster" for "https://github.com/one-kubernetes/fleet-infra"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("d076136fc7ffaac5f215ec706f56aac5af3de42c")
► pushing sync manifests to "https://github.com/one-kubernetes/fleet-infra.git"
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
✔ Kustomization reconciled successfully
► confirming components are healthy
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```

----

### Flux config files

![Flux config files](images/flux_config_files.jpg)

----

### 📄 gotk-sync.yaml

```yaml [2-14|15-27]
# This manifest was generated by flux. DO NOT EDIT.
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  secretRef:
    name: flux-system
  url: ssh://git@github.com/one-kubernetes/fleet-infra
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/mycluster
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

----

### 📄 kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
```

----

### Cloning the git repo locally

```bash
git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}
```

---

## _**⚗️TEST**_ cluster - creating the Flux config

- **ops** va avoir à gérer 2 clusters : _**⚗️TEST**_ et _**🚜PROD**_
- Grace à _Kustomize_, elle va
  1. créer une config. de base
  2. qui sera surchargée par une config. spécifique au _tenant_
- 💡Ça paraît compliqué, mais pas d'inquiétude : la _CLI_ `Flux` s'occupe de l'essentiel

----

![Multi-tenants clusters](images/cluster_multi_tenants.jpg)

----

### The command

```bash [1|2-8]
$ cd ./fleet-infra
$ flux create kustomization tenants    \
    --namespace=flux-system            \
    --source=GitRepository/flux-system \
    --path ./tenants/test           \
    --prune                            \
    --interval=3m                      \
    --export >> clusters/mycluster/tenants.yaml
```

----

### 📄 tenants.yaml

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: tenants
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./tenants/test
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

----

### T04- Don't forget to commit!

> ⚠️ N'oubliez pas de `git commit` et `git push` vers Github : c'est la source qui va être scrutée par `Flux`.

---

# R01- Configuring _**🎸ROCKY**_ deployment with Flux

----

## Creating the _tenant_ dedicated to _**🎸ROCKY**_ team on _**⚗️TEST**_ cluster

```bash
$ mkdir -p ./tenants/base/rocky
$ flux create tenant rocky            \
    --with-namespace=rocky-ns         \
    --cluster-role=rocky-full-access  \
    --export > ./tenants/base/rocky/rbac.yaml
```

----

### 📄 ./tenants/base/rocky/rbac.yaml

```yaml [1-7|9-16|18-36]
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    toolkit.fluxcd.io/tenant: rocky
  name: rocky-ns

---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    toolkit.fluxcd.io/tenant: rocky
  name: rocky
  namespace: rocky-ns

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    toolkit.fluxcd.io/tenant: rocky
  name: rocky-reconciler
  namespace: rocky-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: rocky-full-access
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: gotk:rocky-ns:reconciler
- kind: ServiceAccount
  name: rocky
  namespace: rocky-ns
```

----

## _namespace_ isolation for _**🎸ROCKY**_

```bash
$ cat << EOF | tee ./tenants/base/rocky/cluster-role-rocky.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  namespace: rocky-ns
  name: rocky-full-access
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods", "services", "ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] # You can also use ["*"]
EOF
```

----

## Creating `Github` source in Flux for _**🎸ROCKY**_ git repository

```bash [1-5|6-10|11-13]
$ flux create source git dev1-aspicot                         \
    --namespace=rocky-ns                                       \
    --url=https://github.com/one-kubernetes/dev1-aspicot-app/ \
    --branch=main                                             \
    --export > ./tenants/base/rocky/sync.yaml
$ flux create kustomization rocky        \
    --namespace=rocky-ns                 \
    --service-account=rocky              \
    --source=GitRepository/dev1-aspicot \
    --path="./" --export >> ./tenants/base/rocky/sync.yaml
$ cd ./tenants/base/rocky/
$ kustomize create --autodetect
$ cd -
```

----

### 📄 ./tenants/base/rocky/sync.yaml

```yaml [1-11|13-26]
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: dev1-aspicot
  namespace: rocky-ns
spec:
  interval: 1m0s
  ref:
    branch: main
  url: https://github.com/one-kubernetes/dev1-aspicot-app/

---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: rocky
  namespace: rocky-ns
spec:
  interval: 1m0s
  path: ./
  prune: false
  serviceAccountName: rocky
  sourceRef:
    kind: GitRepository
    name: dev1-aspicot
```

----

### 📄 ./tenants/base/rocky/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- cluster-role-rocky.yaml
- rbac.yaml
- sync.yaml

```

----

### Synchronizing Flux config with its Github repo

Après git commit && git push, on obtient cette arborescence.

![rocky config files](images/dev1_config_files.jpg)

----

## R02- Creating the kustomization in the ROCKY source code repository



- `Flux` scrute le dépôt de _**🎸ROCKY**_, mais il s'attend à y trouver un fichier `kustomization.yaml`
- _**🎸ROCKY**_ doit donc y créer ce fichier

```bash
kustomize create --autodetect
```

----

## Adding a kustomize patch for _**⚗️TEST**_ cluster deployment


```bash [1|2-10|11-20]
$ mkdir -p ./tenants/test/rocky
$ cat << EOF | tee ./tenants/test/rocky/rocky-patch.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: rocky
  namespace: rocky-ns
spec:
  path: ./
EOF
cat << EOF | tee ./tenants/test/rocky/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base/rocky
patches:
  - path: rocky-patch.yaml
    target:
      kind: Kustomization
EOF
```

----

## The whole configuration waterfall

![Flux configuration waterfall](images/flux_config_dependencies.jpg)

----

## Rocky app is deployed on _**⚗️TEST**_ cluster

![rocky Web site](images/dev1_website001.png)

----

## ⚠️ Limitations

- Pour chaque nouveau dépôt applicatif, **ops** doit ajouter une source `Flux`

- _**🎸ROCKY**_ est celui qui produit le `deployment.yaml`
    - et donc, **ops** a peu de latitude pour configurer des comportements différents entre _**⚗️TEST**_ et _**🚜PROD**_

- ça veut dire aussi que _**🎸ROCKY**_ team est seule à décider de son architecture technique (service, base de données, etc.) ce qui peut être utile en TEST, moins réaliste en _**🚜PROD**_.

---

# Configuring _**🎻CLASSY**_ deployment with Flux and Helm Chart

For _**🎻CLASSY**_ team, we adopt another strategy that is to deploy with a Helm charts

---

## Why using Helm charts?

- Because dev can just be working on their app source code
- And the final packaging (including technical architecture decisions) might be made available by another team
- And finally, app and stack configuration might be done by the deploying team (meaning either _**🎻CLASSY**_ or ops depending on the ENV)

---

### C01- Creating the Helm chart for _**🎻CLASSY**_ app deployment

🚧 TBD. see: https://github.com/one-kubernetes/classy-helm-charts/tree/main/charts/dev2-carapuce

---

### Publishing Helm chart in an Chart repository

🚧 TBD. see: https://github.com/one-kubernetes/classy-helm-charts/tree/main/charts/dev2-carapuce

---

### Helm - for more info

Reference to the `Flux` chapter in High Five M3 module

---

## C02- Creating the _tenant_ dedicated to _**🎻CLASSY**_ team on _**⚗️TEST**_ cluster

Créer le tenant dédié à _**🎻CLASSY**_ se fait de la même manière que pour _**🎸ROCKY**_

1. création de l'arborescence de configuration du _tenant_
2. création du _namespace_
3. isolation du _namespace_ (ServiceAccount, RoleBinding, Role)

----

## Creating the `Helm` source in Flux for _**🎻CLASSY**_ Helm chart

⚠️ Là par contre, les choses changent !

On ne se source plus depuis un dépôt `git` mais depuis un dépôt de _charts_ `Helm`

```bash [1-4]
$ flux create source helm charts                            \
    --url=https://one-kubernetes.github.io/classy-helm-charts \
    --interval=3m                                           \
    --export > ./tenants/base/classy/sync.yaml
```

----

## Creating the `HelmRelease` in Flux

```bash [1-7|9]
$ flux create helmrelease dev2-carapuce        \
    --namespace=classy-ns                        \
    --service-account=classy                     \
    --source=HelmRepository/charts.flux-system \
    --chart=dev2-carapuce-helm                 \
    --chart-version="0.1.0"                    \
    --export >> ./tenants/base/classy/sync.yaml

$ cd ./tenants/base/classy/ && kustomize create --autodetect
```

----

### 📄 ./tenants/base/classy/sync.yaml

```yaml [1-9|11-16|17-27]
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: charts
  namespace: classy-ns
spec:
  interval: 3m0s
  url: https://one-kubernetes.github.io/classy-helm-charts

---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: dev2-carapuce
  namespace: classy-ns
spec:
  chart:
    spec:
      chart: dev2-carapuce-helm
      sourceRef:
        kind: HelmRepository
        name: charts
        namespace: classy-ns
      version: 0.1.0
  interval: 1m0s
  serviceAccountName: classy
```

----

### C03- Synchro avec le dépôt Github

Après `git commit && git push`, on obtient cette arborescence.

![classy config files](images/dev2_config_files.png)

---

# Really isolated tenants?

---

## _**🎸ROCKY**_ is trying to deploy a new color version of its app

- New version with new color
- But introduces a mistake in the deployment.yaml file (wrong NS)
  
commit

See what happens…

- it might be great to automatically fix this kind of mistake by enforcing the Namespace and the service account that are configured for deploying _**🎸ROCKY**_ app.

---

## introducing Kyverno

Kyverno is a tool to extend Kubernetes permission management to express complex policies.

---

### Kyverno -- for more info

Reference to the `Kyverno` chapter in High Five M4 module

---

## Download Kyverno distribution
```bash
mkdir -p clusters/mycluster/kyverno
```
```bash
wget https://raw.githubusercontent.com/kyverno/kyverno/v1.5.4/definitions/release/install.yaml -O clusters/mycluster/kyverno/kyverno-components.yaml
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Install Kyverno on cluster
```bash
flux create kustomization kyverno --prune true --interval 10m --path ./clusters/mycluster/kyverno --wait true --source GitRepository/flux-system --export > ./clusters/mycluster/kyverno/sync.yaml
```
```bash
cd ./clusters/mycluster/kyverno/ && kustomize create --autodetect
```
```bash
cd -
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Add Kyverno policy to enforce use of Service Account

```bash
mkdir -p clusters/mycluster/kyverno-policies
```
```bash
cat << EOF | tee ./clusters/mycluster/kyverno-policies/enforce-service-account.yaml
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: flux-multi-tenancy
spec:
  validationFailureAction: enforce
  rules:
    - name: serviceAccountName
      exclude:
        resources:
          namespaces:
            - flux-system
      match:
        resources:
          kinds:
            - Kustomization
            - HelmRelease
      validate:
        message: ".spec.serviceAccountName is required"
        pattern:
          spec:
            serviceAccountName: "?*"
    - name: kustomizationSourceRefNamespace
      exclude:
        resources:
          namespaces:
            - flux-system
      match:
        resources:
          kinds:
            - Kustomization
      preconditions:
        any:
          - key: "{{request.object.spec.sourceRef.namespace}}"
            operator: NotEquals
            value: ""
      validate:
        message: "spec.sourceRef.namespace must be the same as metadata.namespace"
        deny:
          conditions:
            - key: "{{request.object.spec.sourceRef.namespace}}"
              operator: NotEquals
              value:  "{{request.object.metadata.namespace}}"
    - name: helmReleaseSourceRefNamespace
      exclude:
        resources:
          namespaces:
            - flux-system
      match:
        resources:
          kinds:
            - HelmRelease
      preconditions:
        any:
          - key: "{{request.object.spec.chart.spec.sourceRef.namespace}}"
            operator: NotEquals
            value: ""
      validate:
        message: "spec.chart.spec.sourceRef.namespace must be the same as metadata.namespace"
        deny:
          conditions:
            - key: "{{request.object.spec.chart.spec.sourceRef.namespace}}"
              operator: NotEquals
              value:  "{{request.object.metadata.namespace}}"
EOF
```
```bash
flux create kustomization kyverno-policies --prune true --interval 10m --path ./clusters/mycluster/kyverno-policies --wait true --source GitRepository/flux-system --export > ./clusters/mycluster/kyverno-policies/sync.yaml
```
```bash
cd ./clusters/mycluster/kyverno-policies/ && kustomize create --autodetect
```
```bash
cd -
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Apply Kyverno policy
```bash
flux create kustomization kyverno-policies --prune true --interval 5m --path ./clusters/mycluster/kyverno-policies --source GitRepository/flux-system --depends-on kyverno --export > ./clusters/mycluster/kyverno-policies/sync.yaml
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Add Kyverno dependency for _**⚗️TEST**_ cluster
```bash
flux create kustomization tenants --prune true --interval 5m --path ./tenants/test --source GitRepository/flux-system --depends-on kyverno-policies --export > ./clusters/mycluster/tenants.yaml
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Fix Kyverno policy
```bash
flux create source helm charts --url=https://one-kubernetes.github.io/classy-helm-charts --interval=3m --namespace classy-ns --export > ./tenants/base/classy/sync.yaml
```
```bash
flux create helmrelease dev2-carapuce --namespace=classy-ns --service-account=classy --source=HelmRepository/charts.classy-ns --chart=dev2-carapuce-helm --chart-version="0.1.0" --export >> ./tenants/base/classy/sync.yaml
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

# Network leak

🚧 _**🎸ROCKY**_ upgrades its app and finally create an error because its app is connecting to _**🎻CLASSY**_ database, running in another namespace.
Introducing Pod network policies to avoid such kind of thing.

___

# Switching to _**🚜PROD**_ env

---

## Creating the _**🚜PROD**_ cluster in Digital Ocean

🚧

---

## Installing and configuring Flux for _**🚜PROD**_ cluster

🚧

Installing Flux
Adding Github source
Adding Kustomize patches so that the cluster is taken into account.

---

# using CloudNativePG instead of stand-alone PostgreSQL on _**🚜PROD**_ cluster

🚧 Instead of having _**🎸ROCKY**_ team deploying a stand-alone ephemeral PostgreSQL, we'll introduce CloudNativePG and make it available for dev teams to use it as a PostgreSQL provider.


---

# Install cert-manager on _**🚜PROD**_ cluster

🚧 exposing _**🎸ROCKY**_ team with HTTPs.

---

# Install monitoring stack

---

## Install Prometheus
```bash
mkdir -p clusters/mycluster/kube-prometheus-stack
```
```bash
flux create source helm prometheus-community --url=https://prometheus-community.github.io/helm-charts --interval=1m --export > clusters/mycluster/kube-prometheus-stack/sync.yaml
```
```bash
cat << EOF | tee ./clusters/mycluster/kube-prometheus-stack/values.yaml
alertmanager:
  enabled: false
grafana:
  sidecar:
    dashboards:
      searchNamespace: ALL
prometheus:
  prometheusSpec:
    podMonitorSelector:
      matchLabels:
        app.kubernetes.io/part-of: flux
EOF
```
```bash
flux create helmrelease kube-prometheus-stack --chart kube-prometheus-stack --source HelmRepository/prometheus-community --chart-version 31.0.0 --crds CreateReplace --export --target-namespace monitoring --create-target-namespace true --values ./clusters/mycluster/kube-prometheus-stack/values.yaml >> ./clusters/mycluster/kube-prometheus-stack/sync.yaml
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Install Flux Grafana dashboards
```bash
mkdir -p clusters/mycluster/kube-prometheus-stack-config
```
```bash
cat << EOF | tee ./clusters/mycluster/kube-prometheus-stack-config/podmonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: flux-system
  namespace: flux-system
  labels:
    app.kubernetes.io/part-of: flux
spec:
  namespaceSelector:
    matchNames:
      - flux-system
  selector:
    matchExpressions:
      - key: app
        operator: In
        values:
          - helm-controller
          - source-controller
          - kustomize-controller
          - notification-controller
          - image-automation-controller
          - image-reflector-controller
  podMetricsEndpoints:
    - port: http-prom
EOF
```
```bash
wget https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/grafana/dashboards/cluster.json -P ./clusters/mycluster/kube-prometheus-stack-config/
```
```bash
wget https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/grafana/dashboards/control-plane.json -P ./clusters/mycluster/kube-prometheus-stack-config/
```
```bash
cat << EOF | tee ./clusters/mycluster/kube-prometheus-stack-config/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: flux-system
resources:
  - podmonitor.yaml
configMapGenerator:
  - name: flux-grafana-dashboards
    files:
      - control-plane.json
      - cluster.json
    options:
      labels:
        grafana_dashboard: flux-system
EOF
```
> :warning: Remember to commit and push your code each time you make a change so that FluxCD can apply the changes.

---

## Access the Grafana dashboard
```bash
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-stack-grafana 3000:80
```

## Get the Grafana admin password
```bash
kubectl get secret --namespace kube-prometheus-stack kube-prometheus-stack-grafana -o json | jq '.data | map_values(@base64d)'
```

## And browse…

---
