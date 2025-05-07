# Kubernetes distributions and installers

- Sometimes, we need to run Kubernetes ourselves

  (as opposed to "use a managed offering")

- Beware: it takes *a lot of work* to set up and maintain Kubernetes

- It might be necessary if you have specific security or compliance requirements

  (e.g. national security for states that don't have a suitable domestic cloud)

- There are countless [distributions and installers][certified-kubernetes] available

- We can't review them all

[certified-kubernetes]: https://kubernetes.io/partners/#iframe-landscape-conformance

---

## Evolution over time

- 2014 - early days; Kubernetes is installed manually

- 2015 - CoreOS, Rancher

- 2016 - [kops](https://github.com/kubernetes/kops), kubeadm

- 2017 - Kubernetes the hard way, Docker Enterprise

- 2018 - Crossplane, Cluster API, PKS

- 2019 - k3s, Talos

- 2021 - k0s, EKS anywhere

Note: some of these dates might be approximative (should we count
announcements, first commit, first release, release 1.0...), the
goal is to get an overall idea of the evolution of the state of the art.

---

## Example - kubeadm

- Provisions Kubernetes nodes on top of existing machines

- `kubeadm init` to provision a single-node control plane

- `kubeadm join` to join a node to the cluster

- Supports HA control plane [with some extra steps](https://kubernetes.io/docs/setup/independent/high-availability/) 

- Installing a single cluster is easy

- Upgrading a cluster is possible, but must be done carefully

💡 Great to install a single cluster quickly with a reasonable learning curve.

---

## Example - Cluster API

- Provision and manage Kubernetes clusters declaratively

- Clusters, nodes... are represented by Kubernetes resources

- Initial setup is more or less complicated

  (depending on the infrastructure and bootstrap providers used)

- Installing many clusters is then easy

- Upgrading clusters can be fully automated

  (again, depending on infrastructure, bootstrap providers...)

💡 Great to manage dozens or hundreds of clusters, with a bigger initial investment.

---

## Example - Talos Linux

- Based on an immutable system

  (like CoreOS Linux, Flatcar... but learned a lot from these precursors)

- Control plane and nodes are managed declaratively

- Initial setup and upgrades are relatively straightforward

- Some admin tasks require to learn a new way to do things

  (e.g. managing storage, troubleshooting nodes...)

- Managing fleets of clusters is facilitated by Omni (commercial product)

💡 As of 2025, Talos Linux popularity has significantly increased among "trendsetters".

---

## Bottom line

- Each distribution / installer has pros and cons

- Before picking one, we should sort out our priorities:

  - cloud, on-premises, hybrid?

  - integration with existing network/storage architecture or equipment?

  - are we storing very sensitive data, like finance, health, military?

  - how many clusters are we deploying (and maintaining): 2, 10, 50?

  - which team will be responsible for deployment and maintenance?
    <br/>(do they need training?)

  - etc.

???

:EN:- Kubernetes distributions and installers
:FR:- L'offre Kubernetes "on premises"
