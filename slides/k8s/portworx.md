# Portworx

- Portworx is a *commercial* persistent storage solution for containers

- It works with Kubernetes, but also Mesos, Swarm ...

- It provides [hyper-converged](https://en.wikipedia.org/wiki/Hyper-converged_infrastructure) storage

  (=storage is provided by regular compute nodes)

- We're going to use it here because it can be deployed on any Kubernetes cluster

  (it doesn't require any particular infrastructure)

- We don't endorse or support Portworx in any particular way

  (but we appreciate that it's super easy to install!)

---

## A useful reminder

- We're installing Portworx because we need a storage system

- If you are using AKS, EKS, GKE, Kapsule ... you already have a storage system

  (but you might want another one, e.g. to leverage local storage)

- If you have setup Kubernetes yourself, there are other solutions available too

  - on premises, you can use a good old SAN/NAS

  - on a private cloud like OpenStack, you can use e.g. Cinder

  - everywhere, you can use other systems, e.g. Gluster, StorageOS

---

## Installing Portworx

- Portworx installation is relatively simple

- ... But we made it *even simpler!*

- We are going to use a YAML manifest that will take care of everything

- Warning: this manifest is customized for a very specific setup

  (like the VMs that we provide during workshops and training sessions)

- It will probably *not work* If you are using a different setup

  (like Docker Desktop, k3s, MicroK8S, Minikube ...)

---

## The simplified Portworx installer

- The Portworx installation will take a few minutes

- Let's start it, then we'll explain what happens behind the scenes

.lab[

- Install Portworx:
  ```bash
  kubectl apply -f ~/container.training/k8s/portworx.yaml
  ```

]

<!-- ##VERSION ## -->

*Note: this was tested with Kubernetes 1.18. Newer versions may or may not work.*

---

class: extra-details

## What's in this YAML manifest?

- Portworx installation itself, pre-configured for our setup

- A default *Storage Class* using Portworx

- A *Daemon Set* to create loop devices on each node of the cluster

---

class: extra-details

## Portworx installation

- The official way to install Portworx is to use [PX-Central](https://central.portworx.com/)

  (this requires a free account)

- PX-Central will ask us a few questions about our cluster

  (Kubernetes version, on-prem/cloud deployment, etc.)

- Using our answers, it will generate a YAML manifest that we can use

---

class: extra-details

## Portworx storage configuration

- Portworx needs at least one *block device*

- Block device = disk or partition on a disk

- We can see block devices with `lsblk`

  (or `cat /proc/partitions` if we're old school like that!)

- If we don't have a spare disk or partition, we can use a *loop device*

- A loop device is a block device actually backed by a file

- These are frequently used to mount ISO (CD/DVD) images or VM disk images

---

class: extra-details

## Setting up a loop device

- Our `portworx.yaml` manifest includes a *Daemon Set* that will:

  - create a 10 GB (empty) file on each node

  - load the `loop` module (if it's not already loaded)

  - associate a loop device with the 10 GB file

- After these steps, we have a block device that Portworx can use

---

class: extra-details

## Implementation details

- The file is `/portworx.blk`

  (it is a [sparse file](https://en.wikipedia.org/wiki/Sparse_file) created with `truncate`)

- The loop device is `/dev/loop4`

- This can be verified by running `sudo losetup`

- The *Daemon Set* uses a privileged *Init Container*

- We can check the logs of that container with:
  ```bash
    kubectl logs --selector=app=setup-loop4-for-portworx \
            -c setup-loop4-for-portworx
  ```

---

## Waiting for Portworx to be ready

- The installation process will take a few minutes

.lab[

- Check out the logs:
  ```bash
  stern -n kube-system portworx
  ```

- Wait until it gets quiet

  (you should see `portworx service is healthy`, too)

<!--
```longwait PX node status reports portworx service is healthy```
```key ^C```
-->

]

---

## Dynamic provisioning of persistent volumes

- We are going to run PostgreSQL in a Stateful set

- The Stateful set will specify a `volumeClaimTemplate`

- That `volumeClaimTemplate` will create Persistent Volume Claims

- Kubernetes' [dynamic provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) will satisfy these Persistent Volume Claims

  (by creating Persistent Volumes and binding them to the claims)

- The Persistent Volumes are then available for the PostgreSQL pods

---

## Storage Classes

- It's possible that multiple storage systems are available

- Or, that a storage system offers multiple tiers of storage

  (SSD vs. magnetic; mirrored or not; etc.)

- We need to tell Kubernetes *which* system and tier to use

- This is achieved by creating a Storage Class

- A `volumeClaimTemplate` can indicate which Storage Class to use

- It is also possible to mark a Storage Class as "default"

  (it will be used if a `volumeClaimTemplate` doesn't specify one)

---

## Check our default Storage Class

- The YAML manifest applied earlier should define a default storage class

.lab[

- Check that we have a default storage class:
  ```bash
  kubectl get storageclass
  ```

]

There should be a storage class showing as `portworx-replicated (default)`.

---

class: extra-details

## Our default Storage Class

This is our Storage Class (in `k8s/storage-class.yaml`):

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: portworx-replicated
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/portworx-volume
parameters:
 repl: "2"
 priority_io: "high"
```

- It says "use Portworx to create volumes and keep 2 replicas of these volumes"

- The annotation makes this Storage Class the default one

---

class: extra-details

## Troubleshooting Portworx

- If we need to see what's going on with Portworx:
  ```
  PXPOD=$(kubectl -n kube-system get pod -l name=portworx -o json |
          jq -r .items[0].metadata.name)
  kubectl -n kube-system exec $PXPOD -- /opt/pwx/bin/pxctl status
  ```

- We can also connect to Lighthouse (a web UI)

  - check the port with `kubectl -n kube-system get svc px-lighthouse`

  - connect to that port

  - the default login/password is `admin/Password1`

  - then specify `portworx-service` as the endpoint

---

class: extra-details

## Removing Portworx

- Portworx provides a storage driver

- It needs to place itself "above" the Kubelet

  (it installs itself straight on the nodes)

- To remove it, we need to do more than just deleting its Kubernetes resources

- It is done by applying a special label:
  ```
  kubectl label nodes --all px/enabled=remove --overwrite
  ```

- Then removing a bunch of local files:
  ```
  sudo chattr -i /etc/pwx/.private.json
  sudo rm -rf /etc/pwx /opt/pwx
  ```

  (on each node where Portworx was running)

---

## Acknowledgements

The Portworx installation tutorial, and the PostgreSQL example,
were inspired by [Portworx examples on Katacoda](https://katacoda.com/portworx/scenarios/), in particular:

- [installing Portworx on Kubernetes](https://www.katacoda.com/portworx/scenarios/deploy-px-k8s)

  (with adapatations to use a loop device and an embedded key/value store)

- [persistent volumes on Kubernetes using Portworx](https://www.katacoda.com/portworx/scenarios/px-k8s-vol-basic)

  (with adapatations to specify a default Storage Class)

- [HA PostgreSQL on Kubernetes with Portworx](https://www.katacoda.com/portworx/scenarios/px-k8s-postgres-all-in-one)

  (with adaptations to use a Stateful Set and simplify PostgreSQL's setup)

???

:EN:- Hyperconverged storage with Portworx
:FR:- Stockage hyperconvergé avec Portworx
