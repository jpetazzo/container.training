# ArgoCD

- We're going to implement a basic GitOps workflow with ArgoCD

- Pushing to the default branch will automatically deploy to our clusters

- There will be two clusters (`dev` and `prod`)

- The two clusters will have similar (but slightly different) workloads

![ArgoCD Logo](images/argocdlogo.png)

---

## ArgoCD concepts

ArgoCD manages **applications** by **syncing** their **live state** with their **target state**.

- **Application**: a group of Kubernetes resources managed by ArgoCD.
  <br/>
  Also a custom resource (`kind: Application`) managing that group of resources.

- **Application source type**: the **Tool** used to build the application (Kustomize, Helm...)

- **Target state**: the desired state of an **application**, as represented by the git repository.

- **Live state**: the current state of the application on the cluster.

- **Sync status**: whether or not the live state matches the target state.

- **Sync**: the process of making an application move to its target state.
  <br/>
  (e.g. by applying changes to a Kubernetes cluster)

(Check [ArgoCD core concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/) for more definitions!)

---

## Getting ready

- Let's make sure we have two clusters

- It's OK to use local clusters (kind, minikube...)

- We need to install the ArgoCD CLI ([argocd-packages], [argocd-binaries])

- **Highly recommended:** set up CLI completion!

- Of course we'll need a Git service, too

---

## Setting up ArgoCD

- The easiest way is to use upstream YAML manifests

- There is also a [Helm chart][argocd-helmchart] if we need more customization

.lab[

- Create a namespace for ArgoCD and install it there:
  ```bash
  kubectl create namespace argocd
  kubectl apply --namespace argocd -f \
      https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  ```

]

---

## Logging in with the ArgoCD CLI

- The CLI can talk to the ArgoCD API server or to the Kubernetes API server

- For simplicity, we're going to authenticate and communicate with the Kubernetes API

.lab[

- Authenticate with the ArgoCD API (that's what the `--core` flag does):
  ```bash
  argocd login --core
  ```

- Check that everything is fine:
  ```bash
  argocd version
  ```
]

--

🤔 `FATA[0000] error retrieving argocd-cm: configmap "argocd-cm" not found`

---

## ArgoCD CLI shortcomings

- When using "core" authentication, the ArgoCD CLI uses our current Kubernetes context

  (as defined in our kubeconfig file)

- That context need to point to the correct namespace

  (the namespace where we installed ArgoCD)

- In fact, `argocd login --core` doesn't communicate at all with ArgoCD!

  (it only updates a local ArgoCD configuration file)

---

## Trying again in the right namespace

- We will need to run all `argocd` commands in the `argocd` namespace

  (this limitation only applies to "core" authentication; see [issue 14167][issue14167])

.lab[

- Switch to the `argocd` namespace:
  ```bash
  kubectl config set-context --current --namespace argocd
  ```

- Check that we can communicate with the ArgoCD API now:
  ```bash
  argocd version
  ```

]

- Let's have a look at ArgoCD architecture!

---

class: pic

![ArgoCD Architecture](images/argocd_architecture.png)

---

## ArgoCD API Server

The API server is a gRPC/REST server which exposes the API consumed by the Web UI, CLI, and CI/CD systems. It has the following responsibilities:

- application management and status reporting

- invoking of application operations (e.g. sync, rollback, user-defined actions)

- repository and cluster credential management (stored as K8s secrets)

- authentication and auth delegation to external identity providers

- RBAC enforcement

- listener/forwarder for Git webhook events

---

## ArgoCD Repository Server

The repository server is an internal service which maintains a local cache of the Git repositories holding the application manifests. It is responsible for generating and returning the Kubernetes manifests when provided the following inputs:

- repository URL

- revision (commit, tag, branch)

- application path

- template specific settings: parameters, helm values...

---

## ArgoCD Application Controller

The application controller is a Kubernetes controller which continuously monitors running applications and compares the current, live state against the desired target state (as specified in the repo). 

It detects *OutOfSync* application state and optionally takes corrective action. 

It is responsible for invoking any user-defined hooks for lifecycle events (*PreSync, Sync, PostSync*).

---

## Preparing a repository for ArgoCD

- We need a repository with Kubernetes YAML manifests

- You can fork [kubercoins] or create a new, empty repository

- If you create a new, empty repository, add some manifests to it

---

## Add an Application

- An Application can be added to ArgoCD via the web UI or the CLI

  (either way, this will create a custom resource of `kind: Application`)

- The Application should then automatically be deployed to our cluster

  (the application manifests will be "applied" to the cluster)

.lab[

- Let's use the CLI to add an Application:
  ```bash
    argocd app create kubercoins \ 
           --repo https://github.com/`<your_user>/<your_repo>`.git \
           --path . --revision `<branch>` \
           --dest-server https://kubernetes.default.svc \
           --dest-namespace kubercoins-prod
  ```

]

---

## Checking progress

- We can see sync status in the web UI or with the CLI

.lab[

- Let's check app status with the CLI:
  ```bash
  argocd app list
  ```

- We can also check directly with the Kubernetes CLI:
  ```bash
  kubectl get applications
  ```

]

- The app is there and it is `OutOfSync`!

---

## Manual sync with the CLI

- By default the "sync policy" is `manual`

- It can also be set to `auto`, which would check the git repository every 3 minutes

  (this interval can be [configured globally][pollinginterval])

- Manual sync can be triggered with the CLI

.lab[

- Let's force an immediate sync of our app:
  ```bash
    argocd app sync kubercoins
  ```
]

🤔 We're getting errors!

---

## Sync failed

We should receive a failure:

`FATA[0000] Operation has completed with phase: Failed`

And in the output, we see more details:

`Message: one or more objects failed to apply,`
<br/>
`reason: namespaces "kubercoins-prod" not found`

---

## Creating the namespace

- There are multiple ways to achieve that

- We could generate a YAML manifest for the namespace and add it to the git repository

- Or we could use "Sync Options" so that ArgoCD creates it automatically!

- ArgoCD provides many "Sync Options" to handle various edge cases

- Some [others](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/) are: `FailOnSharedResource`, `PruneLast`, `PrunePropagationPolicy`...

---

## Editing the app's sync options

- This can be done through the web UI or the CLI

.lab[

- Let's use the CLI once again:
  ```bash
  argocd app edit kubercoins
  ```

- Add the following to the YAML manifest, at the root level:
  ```yaml
    syncPolicy:
      syncOptions:
        - CreateNamespace=true
  ```

]

---

## Sync again

.lab[

- Let's retry the sync operation:
  ```bash
  argocd app sync kubercoins
  ```

- And check the application status:
  ```bash
  argocd app list
  kubectl get applications
  ```

]

- It should show `Synced` and `Progressing`

- After a while (when all pods are running correctly) it should be `Healthy`

---

## Managing Applications via the Web UI

- ArgoCD is popular in large part due to its browser-based UI

- Let's see how to manage Applications in the web UI

.lab[

- Expose the web dashboard on a local port:
  ```bash
  argocd admin dashboard
  ```

- This command will show the dashboard URL; open it in a browser

- Authentication should be automatic

]

Note: `argocd admin dashboard` is similar to `kubectl port-forward` or `kubectl-proxy`.

(The dashboard remains available as long as `argocd admin dashboard` is running.)

---

## Adding a staging Application

- Let's add another Application for a staging environment

- First, create a new branch (e.g. `staging`) in our kubercoins fork

- Then, in the ArgoCD web UI, click on the "+ NEW APP" button

  (on a narrow display, it might just be "+", right next to buttons looking like 🔄 and ↩️)

- See next slides for details about that form!

---

## Defining the Application

| Field            | Value                                      |
|------------------|--------------------------------------------|
| Application Name | `kubercoins-stg`                           |
| Project Name     | `default`                                  |
| Sync policy      | `Manual`                                   |
| Sync options     | check `auto-create namespace`              |
| Repository URL   | `https://github.com/<username>/<reponame>` |
| Revision         | `<branchname>`                             |
| Path             | `.`                                        |
| Cluster URL      | `https://kubernetes.default.svc`           |
| Namespace        | `kubercoins-stg`                           |

Then click on the "CREATE" button (top left).

---

## Synchronizing the Application

- After creating the app, it should now show up in the app tiles

  (with a yellow outline to indicate that it's out of sync)

- Click on the "SYNC" button on the app tile to show the sync panel

- In the sync panel, click on "SYNCHRONIZE"

- The app will start to synchronize, and should become healthy after a little while

---

## Making changes

- Let's make changes to our application manifests and see what happens

.lab[

- Make a change to a manifest

  (for instance, change the number of replicas of a Deployment)

- Commit that change and push it to the staging branch

- Check the application sync status:
  ```bash
  argocd app list
  ```

]

- After a short period of time (a few minutes max) the app should show up "out of sync"

---

## Automated synchronization

- We don't want to manually sync after every change

  (that wouldn't be true continuous deployment!)

- We're going to enable "auto sync"

- Note that this requires much more rigorous testing and observability!

  (we need to be sure that our changes won't crash our app or even our cluster)

- Argo project also provides [Argo Rollouts][rollouts]

  (a controller and CRDs to provide blue-green, canary deployments...)

- Today we'll just turn on automated sync for the staging namespace

---

## Enabling auto-sync

- In the web UI, go to *Applications* and click on *kubercoins-stg*

- Click on the "DETAILS" button (top left, might be just a "i" sign on narrow displays)

- Click on "ENABLE AUTO-SYNC" (under "SYNC POLICY")

- After a few minutes the changes should show up!

---

## Rolling back

- If we deploy a broken version, how do we recover?

- "The GitOps way": revert the changes in source control

  (see next slide)

- Emergency rollback:

  - disable auto-sync (if it was enabled)

  - on the app page, click on "HISTORY AND ROLLBACK"
    <br/>
    (with the clock-with-backward-arrow icon)

  - click on the "..." button next to the button we want to roll back to

  - click "Rollback" and confirm

---

## Rolling back with GitOps

- The correct way to roll back is rolling back the code in source control

```bash
git checkout staging
git revert HEAD
git push origin staging
```

---

## Working with Helm

- ArgoCD supports different tools to process Kubernetes manifests:

  Kustomize, Helm, Jsonnet, and [Config Management Plugins][cmp]

- Let's how to deploy Helm charts with ArgoCD!

- In the [kubercoins] repository, there is a branch called [helm-branch]

- It provides a generic Helm chart, in the [generic-service] directory

- There are service-specific values YAML files in the [values] directory

- Let's create one application for each of the 5 components of our app!

---

## Creating a Helm Application

- The example below uses "upstream" kubercoins

- Feel free to use your own fork instead!

.lab[

- Create an Application for `hasher`:
  ```bash
    argocd app create hasher \
           --repo https://github.com/jpetazzo/kubercoins.git \
           --path generic-service --revision helm \
           --dest-server https://kubernetes.default.svc \
           --dest-namespace kubercoins-helm \
           --sync-option CreateNamespace=true \
           --values ../values/hasher.yaml \
           --sync-policy=auto
  ```

]

---

## Deploying the rest of the application

- Option 1: repeat the previous command (updating app name and values)

- Option 2: author YAML manifests and apply them

---

## Additional considerations

- When running in production, ArgoCD can be integrated with an [SSO provider][sso]

  - ArgoCD embeds and bundles [Dex] to delegate authentication

  - it can also use an existing OIDC provider (Okta, Keycloak...)

- A single ArgoCD instance can manage multiple clusters 

  (but it's also fine to have one ArgoCD per cluster)

- ArgoCD can be complemented with [Argo Rollouts][rollouts] for advanced rollout control

  (blue/green, canary...)

---

## Acknowledgements

Many thanks to
Anton (Ant) Weiss ([antweiss.com](https://antweiss.com), [@antweiss](https://twitter.com/antweiss))
and
Guilhem Lettron
for contributing an initial version and suggestions to this ArgoCD chapter.

All remaining typos, mistakes, or approximations are mine (Jérôme Petazzoni). 

[argocd-binaries]: https://github.com/argoproj/argo-cd/releases/latest
[argocd-helmchart]: https://artifacthub.io/packages/helm/argo/argocd-apps
[argocd-packages]: https://argo-cd.readthedocs.io/en/stable/cli_installation/
[cmp]: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/
[Dex]: https://github.com/dexidp/dex
[generic-service]: https://github.com/jpetazzo/kubercoins/tree/helm/generic-service
[helm-branch]: https://github.com/jpetazzo/kubercoins/tree/helm
[issue14167]: https://github.com/argoproj/argo-cd/issues/14167
[kubercoins]: https://github.com/jpetazzo/kubercoins
[pollinginterval]: https://argo-cd.readthedocs.io/en/stable/faq/#how-often-does-argo-cd-check-for-changes-to-my-git-or-helm-repository
[rollouts]: https://argoproj.github.io/rollouts/
[sso]: https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#sso
[values]: https://github.com/jpetazzo/kubercoins/tree/helm/values

???

:EN:- Implementing gitops with ArgoCD
:FR:- Workflow gitops avec ArgoCD
