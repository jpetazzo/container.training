# Kubernetes distributions and installers

- There are [countless](https://kubernetes.io/docs/setup/pick-right-solution/) distributions available

- We can't review them all

- We're just going to explore a few options

---

## kops

- Deploys Kubernetes using cloud infrastructure

  (supports AWS, GCE, Digital Ocean ...)

- Leverages special cloud features when possible

  (e.g. Auto Scaling Groups ...)

---

## kubeadm

- Provisions Kubernetes nodes on top of existing machines

- `kubeadm init` to provision a single-node control plane

- `kubeadm join` to join a node to the cluster

- Supports HA control plane [with some extra steps](https://kubernetes.io/docs/setup/independent/high-availability/) 

---

## Kubespray

- Based on Ansible

- Works on bare metal and cloud infrastructure

  (good for hybrid deployments)

- The expert says: ultra flexible; slow; complex

---

## RKE (Rancher Kubernetes Engine)

- Opinionated installer with low requirements

- Requires a set of machines with Docker + SSH access

- Supports highly available etcd and control plane

- The expert says: fast; maintenance can be tricky

---

## Terraform + kubeadm

- Sometimes it is necessary to build a custom solution

- Example use case: 

  - deploying Kubernetes on OpenStack

  - ... with highly available control plane

  - ... and Cloud Controller Manager integration

- Solution: Terraform + kubeadm (kubeadm driven by remote-exec)

  - [GitHub repository](https://github.com/enix/terraform-openstack-kubernetes)

  - [Blog post (in French)](https://enix.io/fr/blog/deployer-kubernetes-1-13-sur-openstack-grace-a-terraform/)

---

## And many more ...

- Docker Enterprise Edition

- [AKS Engine](https://github.com/Azure/aks-engine)

- Pivotal Container Service (PKS)

- Tectonic by CoreOS

- etc.

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
