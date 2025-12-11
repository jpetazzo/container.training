## Running your own lab environments

- To practice outside of live classes, you will need your own cluster

- We'll give you 4 possibilities, depending on your goals:

  - level 0 (no installation required)

  - level 1 (local development cluster)

  - level 2 (cluster with multiple nodes)

  - level 3 ("real" cluster with all the bells and whistles)

---

## Level 0

- Use a free, cloud-based, environment

- Pros: free, and nothing to install locally

- Cons: lots of limitations

  - requires online access

  - resources (CPU, RAM, disk) are limited

  - provides a single-node cluster

  - by default, only available through the online IDE
    <br/>(extra steps required to use local tools and IDE)

  - networking stack is different from a normal cluster

  - cluster might be automatically destroyed once in a while

---

## When is it a good match?

- Great for your first steps with Kubernetes

- Convenient for "bite-sized" learning

  (a few minutes at a time without spending time on installs and setup)

- Not-so-great beyond your first steps

- We recommend to "level up" to a local cluster ASAP!

---

## How to obtain it

- We prepared a "Dev container configuration"

  (that you can use with GitHub Codespaces)

- This requires a GitHub account

  (no credit card or personal information is needed, though)

- Option 1: [follow that link][codespaces]

- Option 2: go to [this repo][repo], click on `<> Code v` and `Create codespace on main`

---

## Level 1

- Install a local Kubernetes dev cluster

- Pros: free, can work with local tools

- Cons:

  - usually, you get a one-node cluster
    <br/>(but some tools let you create multiple nodes)

  - resources can be limited
    <br/>(depends on how much CPU/RAM you have on your machine)

  - cluster is on a private network
    <br/>(not great for labs involving load balancers, ingress controllers...)

  - support for persistent volumes might be limited
    <br/>(or non-existent)

---

## When is it a good match?

- Ideal for most classes and labs

  (from basic to advanced)

- Notable exceptions:

  - when you need multiple "real" nodes
    <br/>(e.g. resource scheduling, cluster autoscaling...)

  - when you want to expose things to the outside world
    <br/>(e.g. ingress, gateway API, cert-manager...)

- Very easy to reset the environment to a clean slate

- Great way to prepare a lab or demo before executing it on a "real" cluster

---

## How to obtain it

- There are many options available to run local Kubernetes clusters!

- If you already have Docker up and running:

  *check [KinD] or [k3d]*

- Otherwise:

  *check [Docker Desktop][docker-desktop] or [Rancher Desktop][rancher-desktop]*

- There are also other options; this is just a shortlist!

[KinD]: https://kind.sigs.k8s.io/
[k3d]:https://k3d.io/
[docker-desktop]: https://docs.docker.com/desktop/use-desktop/kubernetes/
[rancher-desktop]: https://docs.rancherdesktop.io/ui/preferences/kubernetes/

---

## Level 2

- Install a Kubernetes cluster on a few machines

  (physical machines, virtual machines, cloud, on-premises...)

- Pros:

  - very flexible; works almost anywhere (cloud VMs, home lab...)

  - can even run "real" applications (serving real traffic)

- Cons:

  - typically costs some money (hardware investment or cloud costs)

  - still missing a few things compared to a "real" cluster
    <br/>(cloud controller manager, storage class, control plane high availability...)

---

## When is it a good match?

- If you already have a "home lab" or a lab at work

  (because the machines already exist)

- If you want more visibility and/or control:

  - enable alpha/experimental options and features

  - start, stop, view logs... of individual components

- If you want multiple nodes to experiment with scheduling, autoscaling...

- To host applications that remain available when your laptop is offline :)

---

## How to obtain it

- Option 1:

  *provision a few machines; [install `kubeadm`][kubeadm]; use `kubeadm` to install cluster*

- Option 2:

  *use [`labctl`][labctl] to automate the previous steps*

  *(labctl supports [10+ public and private cloud platforms][labctl-vms])*

- Option 3:

  *use the Kubernetes distro of your choice!*

---

## Level 3

- Use a managed Kubernetes cluster

- Pros:

  - it's the real deal!

- Cons:

  - recurring cloud costs

---

## When is it a good match?

- If you want a highly-available cluster and control plane

- To have all the cloud features

  (`LoadBalancer` services, `StorageClass` for stateful apps, cluster autoscaling...)

- To host your first production stacks

---

## How to obtain it

- Option 1:

  *use the CLI / Web UI / Terraform... for your cloud provider*

- Option 2:

  *use [`labctl`][labctl] to provision a cluster with Terraform/OpenTofu*

---

## What's `labctl`?

- `labctl` is the tool that we use to provision virtual machines and clusters for live classes

- It can create and configure hundreds of VMs and clusters in a few minutes

- It supports 10+ cloud providers

- It's very useful if you need to provision many clusters

  (e.g. to run your own workshop with your team!)

- It can also be used to provision a single cluster quickly

  (for testing or educational purposes)

- Its Terraform configurations can also be useful on their own

  (e.g. as a base when building your own infra-as-code)

---

## Our Kubernetes toolbox

- We're going to use a lot of different tools

  (kubectl, stern, helm, k9s, krew, and many more)

- We suggest that you install them progressively

  (when we introduce them, if you think they'll be useful to you!)

- We have also prepared a container image: [jpetazzo/shpod]

- `shpod` contains 30+ Docker and Kubernetes tools

  (along with shell customizations like prompt, completion...)

- You can use it to work with your Kubernetes clusters

- It can also be used as an SSH server if needed

[codespaces]: https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=37004081&skip_quickstart=true
[repo]: https://github.com/jpetazzo/container.training
[kubeadm]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/
[labctl]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs
[labctl-vms]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs/terraform/virtual-machines
[jpetazzo/shpod]: https://github.com/jpetazzo/shpod