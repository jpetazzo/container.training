# Stateful sets

- Stateful sets are a type of resource in the Kubernetes API

  (like pods, deployments, services...)

- They offer mechanisms to deploy scaled stateful applications

- At a first glance, they look like *deployments*:

  - a stateful set defines a pod spec and a number of replicas *R*

  - it will make sure that *R* copies of the pod are running

  - that number can be changed while the stateful set is running

  - updating the pod spec will cause a rolling update to happen

- But they also have some significant differences

---

## Stateful sets unique features

- Pods in a stateful set are numbered (from 0 to *R-1*) and ordered

- They are started and updated in order (from 0 to *R-1*)

- A pod is started (or updated) only when the previous one is ready

- They are stopped in reverse order (from *R-1* to 0)

- Each pod know its identity (i.e. which number it is in the set)

- Each pod can discover the IP address of the others easily

- The pods can persist data on attached volumes

🤔 Wait a minute ... Can't we already attach volumes to pods and deployments?

---

## Revisiting volumes

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) are used for many purposes:

  - sharing data between containers in a pod

  - exposing configuration information and secrets to containers

  - accessing storage systems

- Let's see examples of the latter usage

---

## Volumes types

- There are many [types of volumes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes) available:

  - public cloud storage (GCEPersistentDisk, AWSElasticBlockStore, AzureDisk...)

  - private cloud storage (Cinder, VsphereVolume...)

  - traditional storage systems (NFS, iSCSI, FC...)

  - distributed storage (Ceph, Glusterfs, Portworx...)

- Using a persistent volume requires:

  - creating the volume out-of-band (outside of the Kubernetes API)

  - referencing the volume in the pod description, with all its parameters

---

## Using a cloud volume

Here is a pod definition using an AWS EBS volume (that has to be created first):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-using-my-ebs-volume
spec:
  containers:
  - image: ...
    name: container-using-my-ebs-volume
    volumeMounts:
    - mountPath: /my-ebs
      name: my-ebs-volume
  volumes:
  - name: my-ebs-volume
    awsElasticBlockStore:
      volumeID: vol-049df61146c4d7901
      fsType: ext4
```

---

## Using an NFS volume

Here is another example using a volume on an NFS server:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-using-my-nfs-volume
spec:
  containers:
  - image: ...
    name: container-using-my-nfs-volume
    volumeMounts:
    - mountPath: /my-nfs
      name: my-nfs-volume
  volumes:
  - name: my-nfs-volume
    nfs:
      server: 192.168.0.55
      path: "/exports/assets"
```

---

## Shortcomings of volumes

- Their lifecycle (creation, deletion...) is managed outside of the Kubernetes API

  (we can't just use `kubectl apply/create/delete/...` to manage them)

- If a Deployment uses a volume, all replicas end up using the same volume

- That volume must then support concurrent access

  - some volumes do (e.g. NFS servers support multiple read/write access)

  - some volumes support concurrent reads

  - some volumes support concurrent access for colocated pods

- What we really need is a way for each replica to have its own volume

---

## Individual volumes

- The Pods of a Stateful set can have individual volumes

  (i.e. in a Stateful set with 3 replicas, there will be 3 volumes)

- These volumes can be either:

  - allocated from a pool of pre-existing volumes (disks, partitions ...)

  - created dynamically using a storage system

- This introduces a bunch of new Kubernetes resource types:

  Persistent Volumes, Persistent Volume Claims, Storage Classes

  (and also `volumeClaimTemplates`, that appear within Stateful Set manifests!)

---

## Stateful set recap

- A Stateful sets manages a number of identical pods

  (like a Deployment)

- These pods are numbered, and started/upgraded/stopped in a specific order

- These pods are aware of their number

  (e.g., #0 can decide to be the primary, and #1 can be secondary)

- These pods can find the IP addresses of the other pods in the set

  (through a *headless service*)

- These pods can each have their own persistent storage

  (Deployments cannot do that)

---

# Running a Consul cluster

- Here is a good use-case for Stateful sets!

- We are going to deploy a Consul cluster with 3 nodes

- Consul is a highly-available key/value store

  (like etcd or Zookeeper)

- One easy way to bootstrap a cluster is to tell each node:

  - the addresses of other nodes

  - how many nodes are expected (to know when quorum is reached)

---

## Bootstrapping a Consul cluster

*After reading the Consul documentation carefully (and/or asking around),
we figure out the minimal command-line to run our Consul cluster.*

```
consul agent -data-dir=/consul/data -client=0.0.0.0 -server -ui \
       -bootstrap-expect=3 \
       -retry-join=`X.X.X.X` \
       -retry-join=`Y.Y.Y.Y`
```

- Replace X.X.X.X and Y.Y.Y.Y with the addresses of other nodes

- A node can add its own address (it will work fine)

- ... Which means that we can use the same command-line on all nodes (convenient!)

---

## Cloud Auto-join

- Since version 1.4.0, Consul can use the Kubernetes API to find its peers

- This is called [Cloud Auto-join]

- Instead of passing an IP address, we need to pass a parameter like this:

  ```
  consul agent -retry-join "provider=k8s label_selector=\"app=consul\""
  ```

- Consul needs to be able to talk to the Kubernetes API

- We can provide a `kubeconfig` file

- If Consul runs in a pod, it will use the *service account* of the pod

[Cloud Auto-join]: https://www.consul.io/docs/agent/cloud-auto-join.html#kubernetes-k8s-

---

## Setting up Cloud auto-join

- We need to create a service account for Consul

- We need to create a role that can `list` and `get` pods

- We need to bind that role to the service account

- And of course, we need to make sure that Consul pods use that service account

---

## Putting it all together

- The file `k8s/consul-1.yaml` defines the required resources

  (service account, role, role binding, service, stateful set)

- Inspired by this [excellent tutorial](https://github.com/kelseyhightower/consul-on-kubernetes) by Kelsey Hightower

  (many features from the original tutorial were removed for simplicity)

---

## Running our Consul cluster

- We'll use the provided YAML file

.exercise[

- Create the stateful set and associated service:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-1.yaml
  ```

- Check the logs as the pods come up one after another:
  ```bash
  stern consul
  ```

<!--
```wait Synced node info```
```key ^C```
-->

- Check the health of the cluster:
  ```bash
  kubectl exec consul-0 -- consul members
  ```

]

---

## Caveats

- The scheduler may place two Consul pods on the same node

  - if that node fails, we lose two Consul pods at the same time
  - this will cause the cluster to fail

- Scaling down the cluster will cause it to fail

  - when a Consul member leaves the cluster, it needs to inform the others
  - otherwise, the last remaining node doesn't have quorum and stops functioning

- This Consul cluster doesn't use real persistence yet

  - data is stored in the containers' ephemeral filesystem
  - if a pod fails, its replacement starts from a blank slate

---

## Improving pod placement

- We need to tell the scheduler:

  *do not put two of these pods on the same node!*

- This is done with an `affinity` section like the following one:
  ```yaml
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - consul
            topologyKey: kubernetes.io/hostname
  ```

---

## Using a lifecycle hook

- When a Consul member leaves the cluster, it needs to execute:
  ```bash
  consul leave
  ```

- This is done with a `lifecycle` section like the following one:
  ```yaml
    lifecycle:
      preStop:
        exec:
          command:
          - /bin/sh
          - -c
          - consul leave
  ```

---

## Running a better Consul cluster

- Let's try to add the scheduling constraint and lifecycle hook

- We can do that in the same namespace or another one (as we like)

- If we do that in the same namespace, we will see a rolling update

  (pods will be replaced one by one)

.exercise[

- Deploy a better Consul cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-2.yaml
  ```

]

---

## Still no persistence, though

- We aren't using actual persistence yet

  (no `volumeClaimTemplate`, Persistent Volume, etc.)

- What happens if we lose a pod?

  - a new pod gets rescheduled (with an empty state)

  - the new pod tries to connect to the two others

  - it will be accepted (after 1-2 minutes of instability)

  - and it will retrieve the data from the other pods

---

## Failure modes

- What happens if we lose two pods?

  - manual repair will be required

  - we will need to instruct the remaining one to act solo

  - then rejoin new pods

- What happens if we lose three pods? (aka all of them)

  - we lose all the data (ouch)

- If we run Consul without persistent storage, backups are a good idea!

---

# Persistent Volumes Claims

- Our Pods can use a special volume type: a *Persistent Volume Claim*

- A Persistent Volume Claim (PVC) is also a Kubernetes resource

  (visible with `kubectl get persistentvolumeclaims` or `kubectl get pvc`)

- A PVC is not a volume; it is a *request for a volume*

- It should indicate at least:

  - the size of the volume (e.g. "5 GiB")

  - the access mode (e.g. "read-write by a single pod")

---

## What's in a PVC?

- A PVC contains at least:

  - a list of *access modes* (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)

  - a size (interpreted as the minimal storage space needed)

- It can also contain optional elements:

  - a selector (to restrict which actual volumes it can use)

  - a *storage class* (used by dynamic provisioning, more on that later)

---

## What does a PVC look like?

Here is a manifest for a basic PVC:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
   name: my-claim
spec:
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 1Gi
```

---

## Using a Persistent Volume Claim

Here is a Pod definition like the ones shown earlier, but using a PVC:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-using-a-claim
spec:
  containers:
  - image: ...
    name: container-using-a-claim
    volumeMounts:
    - mountPath: /my-vol
      name: my-volume
  volumes:
  - name: my-volume
    persistentVolumeClaim:
      claimName: my-claim
```

---

## Creating and using Persistent Volume Claims

- PVCs can be created manually and used explicitly

  (as shown on the previous slides)

- They can also be created and used through Stateful Sets

  (this will be shown later)

---

## Lifecycle of Persistent Volume Claims

- When a PVC is created, it starts existing in "Unbound" state

  (without an associated volume)

- A Pod referencing an unbound PVC will not start

  (the scheduler will wait until the PVC is bound to place it)

- A special controller continuously monitors PVCs to associate them with PVs

- If no PV is available, one must be created:

  - manually (by operator intervention)

  - using a *dynamic provisioner* (more on that later)

---

class: extra-details

## Which PV gets associated to a PVC?

- The PV must satisfy the PVC constraints

  (access mode, size, optional selector, optional storage class)

- The PVs with the closest access mode are picked

- Then the PVs with the closest size

- It is possible to specify a `claimRef` when creating a PV

  (this will associate it to the specified PVC, but only if the PV satisfies all the requirements of the PVC; otherwise another PV might end up being picked)

- For all the details about the PersistentVolumeClaimBinder, check [this doc](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/persistent-storage.md#matching-and-binding)

---

## Persistent Volume Claims and Stateful sets

- A Stateful set can define one (or more) `volumeClaimTemplate`

- Each `volumeClaimTemplate` will create one Persistent Volume Claim per pod

- Each pod will therefore have its own individual volume

- These volumes are numbered (like the pods)

- Example:

  - a Stateful set is named `db`
  - it is scaled to replicas
  - it has a `volumeClaimTemplate` named `data`
  - then it will create pods `db-0`, `db-1`, `db-2`
  - these pods will have volumes named `data-db-0`, `data-db-1`, `data-db-2`

---

## Persistent Volume Claims are sticky

- When updating the stateful set (e.g. image upgrade), each pod keeps its volume

- When pods get rescheduled (e.g. node failure), they keep their volume

  (this requires a storage system that is not node-local)

- These volumes are not automatically deleted

  (when the stateful set is scaled down or deleted)

- If a stateful set is scaled back up later, the pods get their data back

---

## Dynamic provisioners

- A *dynamic provisioner* monitors unbound PVCs

- It can create volumes (and the corresponding PV) on the fly

- This requires the PVCs to have a *storage class*

  (annotation `volume.beta.kubernetes.io/storage-provisioner`)

- A dynamic provisioner only acts on PVCs with the right storage class

  (it ignores the other ones)

- Just like `LoadBalancer` services, dynamic provisioners are optional

  (i.e. our cluster may or may not have one pre-installed)

---

## What's a Storage Class?

- A Storage Class is yet another Kubernetes API resource

  (visible with e.g. `kubectl get storageclass` or `kubectl get sc`)

- It indicates which *provisioner* to use

  (which controller will create the actual volume)

- And arbitrary parameters for that provisioner

  (replication levels, type of disk ... anything relevant!)

- Storage Classes are required if we want to use [dynamic provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

  (but we can also create volumes manually, and ignore Storage Classes)

---

## The default storage class

- At most one storage class can be marked as the default class

  (by annotating it with `storageclass.kubernetes.io/is-default-class=true`)

- When a PVC is created, it will be annotated with the default storage class

  (unless it specifies an explicit storage class)

- This only happens at PVC creation

  (existing PVCs are not updated when we mark a class as the default one)

---

## Dynamic provisioning setup

This is how we can achieve fully automated provisioning of persistent storage.

1. Configure a storage system.

   (It needs to have an API, or be capable of automated provisioning of volumes.)

2. Install a dynamic provisioner for this storage system.

   (This is some specific controller code.)

3. Create a Storage Class for this system.

   (It has to match what the dynamic provisioner is expecting.)

4. Annotate the Storage Class to be the default one.

---

## Dynamic provisioning usage

After setting up the system (previous slide), all we need to do is:

*Create a Stateful Set that makes use of a `volumeClaimTemplate`.*

This will trigger the following actions.

1. The Stateful Set creates PVCs according to the `volumeClaimTemplate`.

2. The Stateful Set creates Pods using these PVCs.

3. The PVCs are automatically annotated with our Storage Class.

4. The dynamic provisioner provisions volumes and creates the corresponding PVs.

5. The PersistentVolumeClaimBinder associates the PVs and the PVCs together.

6. PVCs are now bound, the Pods can start.

???

:EN:- Deploying apps with Stateful Sets
:EN:- Example: deploying a Consul cluster
:EN:- Understanding Persistent Volume Claims and Storage Classes
:FR:- Déployer une application avec un *Stateful Set*
:FR:- Example : lancer un cluster Consul
:FR:- Comprendre les *Persistent Volume Claims* et *Storage Classes*

