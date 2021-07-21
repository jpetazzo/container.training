# Setting up Kubernetes

- Kubernetes is made of many components that require careful configuration

- Secure operation typically requires TLS certificates and a local CA

  (certificate authority)

- Setting up everything manually is possible, but rarely done

  (except for learning purposes)

- Let's do a quick overview of available options!

---

## Local development

- Are you writing code that will eventually run on Kubernetes?

- Then it's a good idea to have a development cluster!

- Instead of shipping containers images, we can test them on Kubernetes

- Extremely useful when authoring or testing Kubernetes-specific objects

  (ConfigMaps, Secrets, StatefulSets, Jobs, RBAC, etc.)

- Extremely convenient to quickly test/check what a particular thing looks like

  (e.g. what are the fields a Deployment spec?)

---

## One-node clusters

- It's perfectly fine to work with a cluster that has only one node

- It simplifies a lot of things:

  - pod networking doesn't even need CNI plugins, overlay networks, etc.

  - these clusters can be fully contained (no pun intended) in an easy-to-ship VM or container image

  - some of the security aspects may be simplified (different threat model)

  - images can be built directly on the node (we don't need to ship them with a registry)

- Examples: Docker Desktop, k3d, KinD, MicroK8s, Minikube

  (some of these also support clusters with multiple nodes)

---

## Managed clusters ("Turnkey Solutions")

- Many cloud providers and hosting providers offer "managed Kubernetes"

- The deployment and maintenance of the *control plane* is entirely managed by the provider

  (ideally, clusters can be spun up automatically through an API, CLI, or web interface)

- Given the complexity of Kubernetes, this approach is *strongly recommended*

  (at least for your first production clusters)

- After working for a while with Kubernetes, you will be better equipped to decide:

  - whether to operate it yourself or use a managed offering

  - which offering or which distribution works best for you and your needs

---

## Node management

- Most "Turnkey Solutions" offer fully managed control planes

  (including control plane upgrades, sometimes done automatically)

- However, with most providers, we still need to take care of *nodes*

  (provisioning, upgrading, scaling the nodes)

- Example with Amazon EKS ["managed node groups"](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html):

  *...when bugs or issues are reported [...] you're responsible for deploying these patched AMI versions to your managed node groups.*

---

## Managed clusters differences

- Most providers let you pick which Kubernetes version you want

  - some providers offer up-to-date versions

  - others lag significantly (sometimes by 2 or 3 minor versions)

- Some providers offer multiple networking or storage options

- Others will only support one, tied to their infrastructure

  (changing that is in theory possible, but might be complex or unsupported)

- Some providers let you configure or customize the control plane

  (generally through Kubernetes "feature gates")

---

## Choosing a provider

- Pricing models differ from one provider to another

  - nodes are generally charged at their usual price

  - control plane may be free or incur a small nominal fee

- Beyond pricing, there are *huge* differences in features between providers

- The "major" providers are not always the best ones!

- See [this page](https://kubernetes.io/docs/setup/production-environment/turnkey-solutions/) for a list of available providers

---

## Kubernetes distributions and installers

- If you want to run Kubernetes yourselves, there are many options

  (free, commercial, proprietary, open source ...)

- Some of them are installers, while some are complete platforms

- Some of them leverage other well-known deployment tools

  (like Puppet, Terraform ...)

- There are too many options to list them all

  (check [this page](https://kubernetes.io/partners/#conformance) for an overview!)

---

## kubeadm

- kubeadm is a tool part of Kubernetes to facilitate cluster setup

- Many other installers and distributions use it (but not all of them)

- It can also be used by itself

- Excellent starting point to install Kubernetes on your own machines

  (virtual, physical, it doesn't matter)

- It even supports highly available control planes, or "multi-master"

  (this is more complex, though, because it introduces the need for an API load balancer)

---

## Manual setup

- The resources below are mainly for educational purposes!

- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) by Kelsey Hightower

  - step by step guide to install Kubernetes on Google Cloud

  - covers certificates, high availability ...

  - *“Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.”*

- [Deep Dive into Kubernetes Internals for Builders and Operators](https://www.youtube.com/watch?v=3KtEAa7_duA)

  - conference presentation showing step-by-step control plane setup

  - emphasis on simplicity, not on security and availability

---

## About our training clusters

- How did we set up these Kubernetes clusters that we're using?

--

- We used `kubeadm` on freshly installed VM instances running Ubuntu LTS

    1. Install Docker

    2. Install Kubernetes packages

    3. Run `kubeadm init` on the first node (it deploys the control plane on that node)

    4. Set up  Weave (the overlay network) with a single `kubectl apply` command

    5. Run `kubeadm join` on the other nodes (with the token produced by `kubeadm init`)

    6. Copy the configuration file generated by `kubeadm init`

- Check the [prepare VMs README](https://@@GITREPO@@/blob/master/prepare-vms/README.md) for more details

---

## `kubeadm` "drawbacks"

- Doesn't set up Docker or any other container engine

  (this is by design, to give us choice)

- Doesn't set up the overlay network

  (this is also by design, for the same reasons)

- HA control plane requires [some extra steps](https://kubernetes.io/docs/setup/independent/high-availability/)

- Note that HA control plane also requires setting up a specific API load balancer

  (which is beyond the scope of kubeadm)

???

:EN:- Various ways to install Kubernetes
:FR:- Survol des techniques d'installation de Kubernetes
