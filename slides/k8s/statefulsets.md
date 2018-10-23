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

- The pods can have persistent volumes attached to them

🤔 Wait a minute ... Can't we already attach volumes to pods and deployments?

---

## Volumes and Persistent Volumes

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) are used for many purposes:

  - sharing data between containers in a pod

  - exposing configuration information and secrets to containers

  - accessing storage systems

- The last type of volumes is known as a "Persistent Volume"

---

## Persistent Volumes types

- There are many [types of Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes) available:

  - public cloud storage (GCEPersistentDisk, AWSElasticBlockStore, AzureDisk...)

  - private cloud storage (Cinder, VsphereVolume...)

  - traditional storage systems (NFS, iSCSI, FC...)

  - distributed storage (Ceph, Glusterfs, Portworx...)

- Using a persistent volume requires:

  - creating the volume out-of-band (outside of the Kubernetes API)

  - referencing the volume in the pod description, with all its parameters

---

## Using a Persistent Volume

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

## Shortcomings of Persistent Volumes

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

- Using a Persistent Volume Claim is a two-step process:

  - creating the claim

  - using the claim in a pod (as if it were any other kind of volume)

- Between these two steps, something will happen behind the scenes:

  - Kubernetes will associate an existing volume with the claim

  - ... or dynamically create a volume if possible and necessary

---

## What's in a Persistent Volume Claim?

- At the very least, the claim should indicate:

  - the size of the volume (e.g. "5 GiB")

  - the access mode (e.g. "read-write by a single pod")

- It can also give extra details, like:

  - which storage system to use (e.g. Portworx, EBS...)

  - extra parameters for that storage system

    e.g.: "replicate the data 3 times, and use SSD media"

- The extra details are provided by specifying a Storage Class

---

## What's a Storage Class?

- A Storage Class is yet another Kubernetes API resource

  (visible with e.g. `kubectl get storageclass` or `kubectl get sc`)

- It indicates which *provisioner* to use

- And arbitrary parameters for that provisioner

  (replication levels, type of disk ... anything relevant!)

- It is necessary to define a Storage Class to use [dynamic provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

- Conversely, it is not necessary to define one if you will create volumes manually

  (we will see dynamic provisioning in action later)

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

Here is the same definition as earlier, but using a PVC:

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
    - mountPath: /my-ebs
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

## Stateful sets in action

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
consul agent -data=dir=/consul/data -client=0.0.0.0 -server -ui \
       -bootstrap-expect=3 \
       -retry-join=`X.X.X.X` \
       -retry-join=`Y.Y.Y.Y`
```

- We need to replace X.X.X.X and Y.Y.Y.Y with the addresses of other nodes

- We can specify DNS names, but then they have to be FQDN

- It's OK for a pod to include itself in the list as well

- We can therefore use the same command-line on all nodes (easier!)

---

## Discovering the addresses of other pods

- When a service is created for a stateful set, individual DNS entries are created

- These entries are constructed like this:

  `<name-of-stateful-set>-<n>.<name-of-service>.<namespace>.svc.cluster.local`

- `<n>` is the number of the pod in the set (starting at zero)

- If we deploy Consul in the default namespace, the names could be:

  - `consul-0.consul.default.svc.cluster.local`
  - `consul-1.consul.default.svc.cluster.local`
  - `consul-2.consul.default.svc.cluster.local`

---

## Putting it all together

- The file `k8s/consul.yaml` defines a service and a stateful set

- It has a few extra touches:

  - the name of the namespace is injected through an environment variable

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
