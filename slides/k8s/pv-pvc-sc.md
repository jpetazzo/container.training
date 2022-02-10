# PV, PVC, and Storage Classes

- When an application needs storage, it creates a PersistentVolumeClaim

  (either directly, or through a volume claim template in a Stateful Set)

- The PersistentVolumeClaim is initially `Pending`

- Kubernetes then looks for a suitable PersistentVolume

  (maybe one is immediately available; maybe we need to wait for provisioning)

- Once a suitable PersistentVolume is found, the PVC becomes `Bound`

- The PVC can then be used by a Pod

  (as long as the PVC is `Pending`, the Pod cannot run)

---

## Access modes

- PV and PVC have *access modes*:

  - ReadWriteOnce (only one node can access the volume at a time)

  - ReadWriteMany (multiple nodes can access the volume simultaneously)

  - ReadOnlyMany (multiple nodes can access, but they can't write)

  - ReadWriteOncePod (only one pod can access the volume; new in Kubernetes 1.22)

- A PVC lists the access modes that it requires

- A PV lists the access modes that it supports

⚠️ A PV with only ReadWriteMany won't satisfy a PVC with ReadWriteOnce!

---

## Capacity

- A PVC must express a storage size request

  (field `spec.resources.requests.storage`, in bytes)

- A PV must express its size

  (field `spec.capacity.storage`, in bytes)

- Kubernetes will only match a PV and PVC if the PV is big enough

- These fields are only used for "matchmaking" purposes:

  - nothing prevents the Pod mounting the PVC from using more space

  - nothing requires the PV to actually be that big

---

## Storage Class

- What if we have multiple storage systems available?

  (e.g. NFS and iSCSI; or AzureFile and AzureDisk; or Cinder and Ceph...)

- What if we have a storage system with multiple tiers?

  (e.g. SAN with RAID1 and RAID5; general purpose vs. io optimized EBS...)

- Kubernetes lets us define *storage classes* to represent these

  (see if you have any available at the moment with `kubectl get storageclasses`)

---

## Using storage classes

- Optionally, each PV and each PVC can reference a StorageClass

  (field `spec.storageClassName`)

- When creating a PVC, specifying a StorageClass means

  “use that particular storage system to provision the volume!”

- Storage classes are necessary for [dynamic provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

  (but we can also ignore them and perform manual provisioning)

---

## Default storage class

- We can define a *default storage class*

  (by annotating it with `storageclass.kubernetes.io/is-default-class=true`)

- When a PVC is created,

  **IF** it doesn't indicate which storage class to use

  **AND** there is a default storage class

  **THEN** the PVC `storageClassName` is set to the default storage class

---

## Additional constraints

- A PersistentVolumeClaim can also specify a volume selector

  (referring to labels on the PV)

- A PersistentVolume can also be created with a `claimRef`

  (indicating to which PVC it should be bound)

---

class: extra-details

## Which PV gets associated to a PVC?

- The PV must be `Available`

- The PV must satisfy the PVC constraints

  (access mode, size, optional selector, optional storage class)

- The PVs with the closest access mode are picked

- Then the PVs with the closest size

- It is possible to specify a `claimRef` when creating a PV

  (this will associate it to the specified PVC, but only if the PV satisfies all the requirements of the PVC; otherwise another PV might end up being picked)

- For all the details about the PersistentVolumeClaimBinder, check [this doc](https://github.com/kubernetes/design-proposals-archive/blob/main/storage/persistent-storage.md#matching-and-binding)

---

## Creating a PVC

- Let's create a standalone PVC and see what happens!

.lab[

- Check if we have a StorageClass:
  ```bash
  kubectl get storageclasses
  ```

- Create the PVC:
  ```bash
  kubectl create -f ~/container.training/k8s/pvc.yaml
  ```

- Check the PVC:
  ```bash
  kubectl get pvc
  ```

]

---

## Four possibilities

1. If we have a default StorageClass with *immediate* binding:

   *a PV was created and associated to the PVC*

2. If we have a default StorageClass that *waits for first consumer*:

  *the PVC is still `Pending` but has a `STORAGECLASS`* ⚠️

3. If we don't have a default StorageClass:

  *the PVC is still `Pending`, without a `STORAGECLASS`*

4. If we have a StorageClass, but it doesn't work:

  *the PVC is still `Pending` but has a `STORAGECLASS`* ⚠️

---

## Immediate vs WaitForFirstConsumer

- Immediate = as soon as there is a `Pending` PVC, create a PV

- What if:

  - the PV is only available on a node (e.g. local volume)

  - ...or on a subset of nodes (e.g. SAN HBA, EBS AZ...)

  - the Pod that will use the PVC has scheduling constraints

  - these constraints turn out to be incompatible with the PV

- WaitForFirstConsumer = don't provision the PV until a Pod mounts the PVC

---

## Using the PVC

- Let's mount the PVC in a Pod

- We will use a stray Pod (no Deployment, StatefulSet, etc.)

- We will use @@LINK[k8s/mounter.yaml], shown on the next slide

- We'll need to update the `claimName`! ⚠️

---

```yaml
@@INCLUDE[k8s/mounter.yaml]
```

---

## Running the Pod

.lab[

- Edit the `mounter.yaml` manifest

- Update the `claimName` to put the name of our PVC

- Create the Pod

- Check the status of the PV and PVC

]

Note: this "mounter" Pod can be useful to inspect the content of a PVC.

---

## Scenario 1 & 2

If we have a default Storage Class that can provision PVC dynamically...

- We should now have a new PV

- The PV and the PVC should be `Bound` together

---

## Scenario 3

If we don't have a default Storage Class, we must create the PV manually.

```bash
kubectl create -f ~/container.training/k8s/pv.yaml
```

After a few seconds, check that the PV and PVC are bound:

```bash
kubectl get pv,pvc
```

---

## Scenario 4

If our default Storage Class can't provision a PV, let's do it manually.

The PV must specify the correct `storageClassName`.

```bash
STORAGECLASS=$(kubectl get pvc --selector=container.training/pvc \
               -o jsonpath={..storageClassName})
kubectl patch -f ~/container.training/k8s/pv.yaml --dry-run=client -o yaml \
        --patch '{"spec": {"storageClassName": "'$STORAGECLASS'"}}' \
        | kubectl create -f-
```

Check that the PV and PVC are bound:

```bash
kubectl get pv,pvc
```

---

## Checking the Pod

- If the PVC was `Pending`, then the Pod was `Pending` too

- Once the PVC is `Bound`, the Pod can be scheduled and can run

- Once the Pod is `Running`, check it out with `kubectl attach -ti`

---

## PV and PVC lifecycle

- We can't delete a PV if it's `Bound`

- If we `kubectl delete` it, it goes to `Terminating` state

- We can't delete a PVC if it's in use by a Pod

- Likewise, if we `kubectl delete` it, it goes to `Terminating` state

- Deletion is prevented by *finalizers*

  (=like a post-it note saying “don't delete me!”)

- When the mounting Pods are deleted, their PVCs are freed up

- When PVCs are deleted, their PVs are freed up

???

:EN:- Storage provisioning
:EN:- PV, PVC, StorageClass
:FR:- Création de volumes
:FR:- PV, PVC, et StorageClass
