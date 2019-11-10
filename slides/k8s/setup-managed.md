# Installing a managed cluster

*"The easiest way to install Kubernetes is to get someone
else to do it for you."
<br/>
([Jérôme Petazzoni](https://twitter.com/jpetazzo))*

- Let's see a few options to install managed clusters!

- This is not an exhaustive list

  (the goal is to show the actual steps to get started)

- All the options mentioned here require an account
with a cloud provider

- ... And a credit card

---

## EKS (the old way)

- [Read the doc](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html)

- Create service roles, VPCs, and a bunch of other oddities

- Try to figure out why it doesn't work

- Start over, following an [official AWS blog post](https://aws.amazon.com/blogs/aws/amazon-eks-now-generally-available/)

- Try to find the missing Cloud Formation template

--

.footnote[(╯°□°)╯︵ ┻━┻]

---

## EKS (the new way)

- Install `eksctl`

- Set the usual environment variables

  ([AWS_DEFAULT_REGION](https://docs.aws.amazon.com/general/latest/gr/rande.html#eks_region), AWS_ACCESS_KEY, AWS_SECRET_ACCESS_KEY)

- Create the cluster:
  ```bash
  eksctl create cluster
  ```

- Wait 15-20 minutes (yes, it's sloooooooooooooooooow)

- Add cluster add-ons

  (by default, it doesn't come with metrics-server, logging, etc.)

---

## EKS (cleanup)

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

- Wait a couple of minutes (yes, it's faaaaaaaaast)

- The cluster comes with many add-ons

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

- The cluster has useful components pre-installed, such as the metrics server

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

## More options

- Alibaba Cloud

- [IBM Cloud](https://console.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install)

- OVH

- Scaleway (private beta)

- ...
