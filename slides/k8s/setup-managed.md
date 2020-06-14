# Deploying a managed cluster

*"The easiest way to install Kubernetes is to get someone
else to do it for you."
<br/>
([Jérôme Petazzoni](https://twitter.com/jpetazzo))*

- Let's see a few options to install managed clusters!

- This is not an exhaustive list

  (the goal is to show the actual steps to get started)

- The list is sorted alphabetically

- All the options mentioned here require an account
with a cloud provider

- ... And a credit card

---

## AKS (initial setup)

- Install the Azure CLI

- Login:
  ```bash
  az login
  ```

- Select a [region](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=kubernetes-service&regions=all
)

- Create a "resource group":
  ```bash
  az group create --name my-aks-group --location westeurope
  ```

---

## AKS (create cluster)

- Create the cluster:
  ```bash
  az aks create --resource-group my-aks-group --name my-aks-cluster
  ```

- Wait about 5-10 minutes

- Add credentials to `kubeconfig`:
  ```bash
  az aks get-credentials --resource-group my-aks-group --name my-aks-cluster
  ```

---

## AKS (cleanup)

- Delete the cluster:
  ```bash
  az aks delete --resource-group my-aks-group --name my-aks-cluster
  ```

- Delete the resource group:
  ```bash
  az group delete --resource-group my-aks-group
  ```

- Note: delete actions can take a while too!

  (5-10 minutes as well)

---

## AKS (notes)

- The cluster has useful components pre-installed, such as the metrics server

- There is also a product called [AKS Engine](https://github.com/Azure/aks-engine):

  - leverages ARM (Azure Resource Manager) templates to deploy Kubernetes

  - it's "the library used by AKS"

  - fully customizable

  - think of it as "half-managed" Kubernetes option

---

## Amazon EKS (the old way)

- [Read the doc](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html)

- Create service roles, VPCs, and a bunch of other oddities

- Try to figure out why it doesn't work

- Start over, following an [official AWS blog post](https://aws.amazon.com/blogs/aws/amazon-eks-now-generally-available/)

- Try to find the missing Cloud Formation template

--

.footnote[(╯°□°)╯︵ ┻━┻]

---

## Amazon EKS (the new way)

- Install `eksctl`

- Set the usual environment variables

  ([AWS_DEFAULT_REGION](https://docs.aws.amazon.com/general/latest/gr/rande.html#eks_region), AWS_ACCESS_KEY, AWS_SECRET_ACCESS_KEY)

- Create the cluster:
  ```bash
  eksctl create cluster
  ```

- Cluster can take a long time to be ready (15-20 minutes is typical)

- Add cluster add-ons

  (by default, it doesn't come with metrics-server, logging, etc.)

---

## Amazon EKS (cleanup)

- Delete the cluster:
  ```bash
  eksctl delete cluster <clustername>
  ```

- If you need to find the name of the cluster:
  ```bash
  eksctl get clusters
  ```

.footnote[Note: the AWS documentation has been updated and now includes [eksctl instructions](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html).]

---

## Amazon EKS (notes)

- Convenient if you *have to* use AWS

- Needs extra steps to be truly production-ready

- [Versions tend to be outdated](https://twitter.com/jpetazzo/status/1252948707680686081)

- The only officially supported pod network is the [Amazon VPC CNI plugin](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)

  - integrates tightly with security groups and VPC networking

  - not suitable for high density clusters (with many small pods on big nodes)

  - other plugins [should still work](https://docs.aws.amazon.com/eks/latest/userguide/alternate-cni-plugins.html) but will require extra work

---

## Digital Ocean (initial setup)

- Install `doctl`

- Generate API token (in web console)

- Set up the CLI authentication:
  ```bash
  doctl auth init
  ```
  (It will ask you for the API token)

- Check the list of regions and pick one:
  ```bash
  doctl compute region list
  ```
  (If you don't specify the region later, it will use `nyc1`)

---

## Digital Ocean (create cluster)

- Create the cluster:
  ```bash
  doctl kubernetes cluster create my-do-cluster [--region xxx1]
  ```

- Wait 5 minutes

- Update `kubeconfig`:
  ```bash
  kubectl config use-context do-xxx1-my-do-cluster
  ```

- The cluster comes with some components (like Cilium) but no metrics server

---

## Digital Ocean (cleanup)

- List clusters (if you forgot its name):
  ```bash
  doctl kubernetes cluster list
  ```

- Delete the cluster:
  ```bash
  doctl kubernetes cluster delete my-do-cluster
  ```

---

## GKE (initial setup)

- Install `gcloud`

- Login:
  ```bash
  gcloud auth init
  ```

- Create a "project":
  ```bash
  gcloud projects create my-gke-project
  gcloud config set project my-gke-project
  ```

- Pick a [region](https://cloud.google.com/compute/docs/regions-zones/)

  (example: `europe-west1`, `us-west1`, ...)

---

## GKE (create cluster)

- Create the cluster:
  ```bash
  gcloud container clusters create my-gke-cluster --region us-west1 --num-nodes=2
  ```

  (without `--num-nodes` you might exhaust your IP address quota!)

- The first time you try to create a cluster in a given project, you get an error

  - you need to enable the Kubernetes Engine API
  - the error message gives you a link
  - follow the link and enable the API (and billing)
    <br/>(it's just a couple of clicks and it's instantaneous)

- Clutser should be ready in a couple of minutes

---

## GKE (cleanup)

- List clusters (if you forgot its name):
  ```bash
  gcloud container clusters list
  ```

- Delete the cluster:
  ```bash
  gcloud container clusters delete my-gke-cluster --region us-west1
  ```

- Delete the project (optional):
  ```bash
  gcloud projects delete my-gke-project
  ```

---

## GKE (notes)

- Well-rounded product overall

  (it used to be one of the best managed Kubernetes offerings available;
  now that many other providers entered the game, that title is debatable)

- The cluster comes with many add-ons

- Versions lag a bit:

  - latest minor version (e.g. 1.18) tends to be unsupported
 
  - previous minor version (e.g. 1.17) supported through alpha channel

  - previous versions (e.g. 1.14-1.16) supported

---

## Scaleway (initial setup)

- After creating your account, make sure you set a password or get an API key

  (by default, it uses email "magic links" to sign in)

- Install `scw`

  (you need [CLI v2](https://github.com/scaleway/scaleway-cli/tree/v2#Installation), which in beta as of May 2020)

- Generate the CLI configuration with `scw init`

  (it will prompt for your API key, or email + password)

---

## Scaleway (create cluster)

- Create the cluster:
  ```bash
    k8s cluster create name=my-kapsule-cluster version=1.18.3 cni=cilium \
        default-pool-config.node-type=DEV1-M default-pool-config.size=3 
  ```

- After less than 5 minutes, cluster state will be `ready`

  (check cluster status with e.g. `scw k8s cluster list` on a wide terminal
)

- Add connection information to your `.kube/config` file:
  ```bash
  scw k8s kubeconfig install `CLUSTERID`
  ```

  (the cluster ID is shown by `scw k8s cluster list`)

---

class: extra-details

## Scaleway (automation)

- If you want to obtain the cluster ID programmatically, this will do it:

  ```bash
  scw k8s cluster list
  # or
  CLUSTERID=$(scw k8s cluster list -o json | \
        jq -r '.[] | select(.name="my-kapsule-cluster") | .id')
  ```

---

## Scaleway (cleanup)

- Get cluster ID (e.g. with `scw k8s cluster list`)

- Delete the cluster:
  ```bash
  scw cluster delete cluster-id=$CLUSTERID
  ```

- Warning: as of May 2020, load balancers have to be deleted separately!

---

## Scaleway (notes)

- The `create` command is a bit more complex than with other providers

  (you must specify the Kubernetes version, CNI plugin, and node type)

- To see available versions and CNI plugins, run `scw k8s version list`

- As of May 2020, Kapsule supports:

  - multiple CNI plugins, including: cilium, calico, weave, flannel

  - Kubernetes versions 1.15 to 1.18

  - multiple container runtimes, including: Docker, containerd, CRI-O

- To see available node types and their price, check their [pricing page](
https://www.scaleway.com/en/pricing/)

---

## More options

- Alibaba Cloud

- [IBM Cloud](https://console.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install)

- [Linode Kubernetes Engine (LKE)](https://www.linode.com/products/kubernetes/)

- OVHcloud [Managed Kubernetes Service](https://www.ovhcloud.com/en/public-cloud/kubernetes/)

- ...

???

:EN:- Installing a managed cluster
:FR:- Installer un cluster infogéré
