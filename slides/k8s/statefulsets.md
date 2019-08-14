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

## Persistent Volume Claims

- To abstract the different types of storage, a pod can use a special volume type

- This type is a *Persistent Volume Claim*

- A Persistent Volume Claim (PVC) is a resource type

  (visible with `kubectl get persistentvolumeclaims` or `kubectl get pvc`)

- A PVC is not a volume; it is a *request for a volume*

---

## Persistent Volume Claims in practice

- Using a Persistent Volume Claim is a two-step process:

  - creating the claim

  - using the claim in a pod (as if it were any other kind of volume)

- A PVC starts by being Unbound (without an associated volume)

- Once it is associated with a Persistent Volume, it becomes Bound

- A Pod referring an unbound PVC will not start

  (but as soon as the PVC is bound, the Pod can start)

---

## Binding PV and PVC

- A Kubernetes controller continuously watches PV and PVC objects

- When it notices an unbound PVC, it tries to find a satisfactory PV

  ("satisfactory" in terms of size and other characteristics; see next slide)

- If no PV fits the PVC, a PV can be created dynamically

  (this requires to configure a *dynamic provisioner*, more on that later)

- Otherwise, the PVC remains unbound indefinitely

  (until we manually create a PV or setup dynamic provisioning)

---

## What's in a Persistent Volume Claim?

- At the very least, the claim should indicate:

  - the size of the volume (e.g. "5 GiB")

  - the access mode (e.g. "read-write by a single pod")

- Optionally, it can also specify a Storage Class

- The Storage Class indicates:

  - which storage system to use (e.g. Portworx, EBS...)

  - extra parameters for that storage system

    e.g.: "replicate the data 3 times, and use SSD media"

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

## Defining a Persistent Volume Claim

Here is a minimal PVC:

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

## Persistent Volume Claims and Stateful sets

- The pods in a stateful set can define a `volumeClaimTemplate`

- A `volumeClaimTemplate` will dynamically create one Persistent Volume Claim per pod

- Each pod will therefore have its own volume

- These volumes are numbered (like the pods)

- When updating the stateful set (e.g. image upgrade), each pod keeps its volume

- When pods get rescheduled (e.g. node failure), they keep their volume

  (this requires a storage system that is not node-local)

- These volumes are not automatically deleted

  (when the stateful set is scaled down or deleted)

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

- The same command-line can be used on all nodes (convenient!)

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

- The file `k8s/consul.yaml` defines the required resources

  (service account, cluster role, cluster role binding, service, stateful set)

- It has a few extra touches:

  - a `podAntiAffinity` prevents two pods from running on the same node

  - a `preStop` hook makes the pod leave the cluster when shutdown gracefully

This was inspired by this [excellent tutorial](https://github.com/kelseyhightower/consul-on-kubernetes) by Kelsey Hightower.
Some features from the original tutorial (TLS authentication between
nodes and encryption of gossip traffic) were removed for simplicity.

---

## Running our Consul cluster

- We'll use the provided YAML file

.exercise[

- Create the stateful set and associated service:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul.yaml
  ```

- Check the logs as the pods come up one after another:
  ```bash
  stern consul
  ```

<!--
```wait Synced node info```
```keys ^C```
-->

- Check the health of the cluster:
  ```bash
  kubectl exec consul-0 consul members
  ```

]

---

## Caveats

- We haven't used a `volumeClaimTemplate` here

- That's because we don't have a storage provider yet

  (except if you're running this on your own and your cluster has one)

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
