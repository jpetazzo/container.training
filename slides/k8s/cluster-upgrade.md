# Upgrading clusters

**(Note: we won't do the labs for that section!)**

- It's *recommended* to run consistent versions across a cluster

  (mostly to have feature parity and latest security updates)

- It's not *mandatory*

  (otherwise, cluster upgrades would be a nightmare!)

- Components can be upgraded one at a time without problems

<!-- ##VERSION## -->

---

## Checking what we're running

- It's easy to check the version for the API server

.lab[

- Log into node `oldversion1`

- Check the version of kubectl and of the API server:
  ```bash
  kubectl version
  ```

]

- In a HA setup with multiple API servers, they can have different versions

- Running the command above multiple times can return different values

---

## Node versions

- It's also easy to check the version of kubelet

.lab[

- Check node versions (includes kubelet, kernel, container engine):
  ```bash
  kubectl get nodes -o wide
  ```

]

- Different nodes can run different kubelet versions

- Different nodes can run different kernel versions

- Different nodes can run different container engines

---

## Control plane versions

- If the control plane is self-hosted (running in pods), we can check it

.lab[

- Show image versions for all pods in `kube-system` namespace:
  ```bash
    kubectl --namespace=kube-system get pods -o json \
            | jq -r '
              .items[]
              | [.spec.nodeName, .metadata.name]
                + 
                (.spec.containers[].image | split(":"))
              | @tsv
              ' \
            | column -t
  ```

]

---

## What version are we running anyway?

- When I say, "I'm running Kubernetes 1.28", is that the version of:

  - kubectl

  - API server

  - kubelet

  - controller manager

  - something else?

---

## Other versions that are important

- etcd

- kube-dns or CoreDNS

- CNI plugin(s)

- Network controller, network policy controller

- Container engine

- Linux kernel

---

## Important questions

- Should we upgrade the control plane before or after the kubelets?

- Within the control plane, should we upgrade the API server first or last?

- How often should we upgrade?

- How long are versions maintained?

- All the answers are in [the documentation about version skew policy](https://kubernetes.io/docs/setup/release/version-skew-policy/)!

- Let's review the key elements together ...

---

## Kubernetes uses semantic versioning

- Kubernetes versions look like MAJOR.MINOR.PATCH; e.g. in 1.28.9:

  - MAJOR = 1
  - MINOR = 28
  - PATCH = 9

- It's always possible to mix and match different PATCH releases

  (e.g. 1.28.9 and 1.28.13 are compatible)

- It is recommended to run the latest PATCH release

  (but it's mandatory only when there is a security advisory)

---

## Version skew

- API server must be more recent than its clients (kubelet and control plane)

- ... Which means it must always be upgraded first

- All components support a difference of one¹ MINOR version

- This allows live upgrades (since we can mix e.g. 1.28 and 1.29)

- It also means that going from 1.28 to 1.30 requires going through 1.29

.footnote[¹Except kubelet, which can be up to two MINOR behind API server,
and kubectl, which can be one MINOR ahead or behind API server.]

---

## Release cycle

- There is a new PATCH relese whenever necessary

  (every few weeks, or "ASAP" when there is a security vulnerability)

- There is a new MINOR release every 3 months (approximately)

- At any given time, three MINOR releases are maintained

- ... Which means that MINOR releases are maintained approximately 9 months

- We should expect to upgrade at least every 3 months (on average)

---

## General guidelines

- To update a component, use whatever was used to install it

- If it's a distro package, update that distro package

- If it's a container or pod, update that container or pod

- If you used configuration management, update with that

---

## Know where your binaries come from

- Sometimes, we need to upgrade *quickly*

  (when a vulnerability is announced and patched)

- If we are using an installer, we should:

  - make sure it's using upstream packages

  - or make sure that whatever packages it uses are current

  - make sure we can tell it to pin specific component versions

---

## In practice

- We are going to update a few cluster components

- We will change the kubelet version on one node

- We will change the version of the API server

- We will work with cluster `oldversion` (nodes `oldversion1`, `oldversion2`, `oldversion3`)

---

## Updating the API server

- This cluster has been deployed with kubeadm

- The control plane runs in *static pods*

- These pods are started automatically by kubelet

  (even when kubelet can't contact the API server)

- They are defined in YAML files in `/etc/kubernetes/manifests`

  (this path is set by a kubelet command-line flag)

- kubelet automatically updates the pods when the files are changed

---

## Changing the API server version

- We will edit the YAML file to use a different image version

.lab[

- Log into node `oldversion1`

- Check API server version:
  ```bash
  kubectl version
  ```

- Edit the API server pod manifest:
  ```bash
  sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

- Look for the `image:` line, and update it to e.g. `v1.30.1`

]

---

## Checking what we've done

- The API server will be briefly unavailable while kubelet restarts it

.lab[

- Check the API server version:
  ```bash
  kubectl version
  ```

]

---

## Was that a good idea?

--

**No!**

--

- Remember the guideline we gave earlier:

  *To update a component, use whatever was used to install it.*

- This control plane was deployed with kubeadm

- We should use kubeadm to upgrade it!

---

## Updating the whole control plane

- Let's make it right, and use kubeadm to upgrade the entire control plane

  (note: this is possible only because the cluster was installed with kubeadm)

.lab[

- Check what will be upgraded:
  ```bash
  sudo kubeadm upgrade plan
  ```

]

Note 1: kubeadm thinks that our cluster is running 1.24.1.
<br/>It is confused by our manual upgrade of the API server!

Note 2: kubeadm itself is still version 1.22.1..
<br/>It doesn't know how to upgrade do 1.23.X.

---

## Upgrading kubeadm

- First things first: we need to upgrade kubeadm

- The Kubernetes package repositories are now split by minor versions

  (i.e. there is one repository for 1.28, another for 1.29, etc.)

- This avoids accidentally upgrading from one minor version to another

  (e.g. with unattended upgrades or if packages haven't been held/pinned)

- We'll need to add the new package repository and unpin packages!

---

## Installing the new packages

- Edit `/etc/apt/sources.list.d/kubernetes.list`

  (or copy it to e.g. `kubernetes-1.29.list` and edit that)

- `apt-get update`

- Now edit (or remove) `/etc/apt/preferences.d/kubernetes`

- `apt-get install kubeadm` should now upgrade `kubeadm` correctly! 🎉

---

## Reverting our manual API server upgrade

- First, we should revert our `image:` change

  (so that kubeadm executes the right migration steps)

.lab[

- Edit the API server pod manifest:
  ```bash
  sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
  ```

- Look for the `image:` line, and restore it to the original value

  (e.g. `v1.28.9`)

- Wait for the control plane to come back up

]

---

## Upgrading the cluster with kubeadm

- Now we can let kubeadm do its job!

.lab[

- Check the upgrade plan:
  ```bash
  sudo kubeadm upgrade plan
  ```

- Perform the upgrade:
  ```bash
  sudo kubeadm upgrade apply v1.29.0
  ```

]

---

## Updating kubelet

- These nodes have been installed using the official Kubernetes packages

- We can therefore use `apt` or `apt-get`

.lab[

- Log into node `oldversion2`

- Update package lists and APT pins like we did before

- Then upgrade kubelet

]

---

## Checking what we've done

.lab[

- Log into node `oldversion1`

- Check node versions:
  ```bash
  kubectl get nodes -o wide
  ```

- Create a deployment and scale it to make sure that the node still works

]

---

## Was that a good idea?

--

**Almost!**

--

- Yes, kubelet was installed with distribution packages

- However, kubeadm took care of configuring kubelet

  (when doing `kubeadm join ...`)

- We were supposed to run a special command *before* upgrading kubelet!

- That command should be executed on each node

- It will download the kubelet configuration generated by kubeadm

---

## Upgrading kubelet the right way

- We need to upgrade kubeadm, upgrade kubelet config, then upgrade kubelet

  (after upgrading the control plane)

.lab[

- Execute the whole upgrade procedure on each node:
  ```bash
    for N in 1 2 3; do
      ssh oldversion$N "
        sudo sed -i s/1.28/1.29/ /etc/apt/sources.list.d/kubernetes.list &&
        sudo rm /etc/apt/preferences.d/kubernetes &&
        sudo apt update &&
        sudo apt install kubeadm -y &&
        sudo kubeadm upgrade node &&
        sudo apt install kubelet -y"
    done
  ```
]

---

## Checking what we've done

- All our nodes should now be updated to version 1.29

.lab[

- Check nodes versions:
  ```bash
  kubectl get nodes -o wide
  ```

]

---

## And now, was that a good idea?

--

**Almost!**

--

- The official recommendation is to *drain* a node before performing node maintenance

  (migrate all workloads off the node before upgrading it)

- How do we do that?

- Is it really necessary?

- Let's see!

---

## Draining a node

- This can be achieved with the `kubectl drain` command, which will:

  - *cordon* the node (prevent new pods from being scheduled there)

  - *evict* all the pods running on the node (delete them gracefully)

  - the evicted pods will automatically be recreated somewhere else

  - evictions might be blocked in some cases (Pod Disruption Budgets, `emptyDir` volumes)

- Once the node is drained, it can safely be upgraded, restarted...

- Once it's ready, it can be put back in commission with `kubectl uncordon`

---

## Is it necessary?

- When upgrading kubelet from one patch-level version to another:

  - it's *probably fine*

- When upgrading system packages:

  - it's *probably fine*

  - except [when it's not][datadog-systemd-outage]

- When upgrading the kernel:

  - it's *probably fine*

  - ...as long as we can tolerate a restart of the containers on the node

  - ...and that they will be unavailable for a few minutes (during the reboot)

[datadog-systemd-outage]: https://www.datadoghq.com/blog/engineering/2023-03-08-deep-dive-into-platform-level-impact/

---

## Is it necessary?

- When upgrading kubelet from one minor version to another:

  - it *may or may not be fine*

  - in some cases (e.g. migrating from Docker to containerd) it *will not*

- Here's what [the documentation][node-upgrade-docs] says:

  *Draining nodes before upgrading kubelet ensures that pods are re-admitted and containers are re-created, which may be necessary to resolve some security issues or other important bugs.*

- Do it at your own risk, and if you do, test extensively in staging environments!

[node-upgrade-docs]: https://kubernetes.io/docs/tasks/administer-cluster/cluster-upgrade/#manual-deployments

---

## Database operators to the rescue

- Moving stateful pods (e.g.: database server) can cause downtime

- Database replication can help:

  - if a node contains database servers, we make sure these servers aren't primaries

  - if they are primaries, we execute a *switch over*

- Some database operators (e.g. [CNPG]) will do that switch over automatically

  (when they detect that a node has been *cordoned*)

[CNPG]: https://cloudnative-pg.io/

---

class: extra-details

## Skipping versions

- This example worked because we went from 1.28 to 1.29

- If you are upgrading from e.g. 1.26, you will have to go through 1.27 first

- This means upgrading kubeadm to 1.27.X, then using it to upgrade the cluster

- Then upgrading kubeadm to 1.28.X, etc.

- **Make sure to read the release notes before upgrading!**

???

:EN:- Best practices for cluster upgrades
:EN:- Example: upgrading a kubeadm cluster

:FR:- Bonnes pratiques pour la mise à jour des clusters
:FR:- Exemple : mettre à jour un cluster kubeadm
