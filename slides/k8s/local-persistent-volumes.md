# Local Persistent Volumes

- We want to run that Consul cluster *and* actually persist data

- But we don't have a distributed storage system

- We are going to use local volumes instead

  (similar conceptually to `hostPath` volumes)

- We can use local volumes without installing extra plugins

- However, they are tied to a node

- If that node goes down, the volume becomes unavailable

---

## With or without dynamic provisioning

- We will deploy a Consul cluster *with* persistence

- That cluster's StatefulSet will create PVCs

- These PVCs will remain unbound¹, until we will create local volumes manually

  (we will basically do the job of the dynamic provisioner)

- Then, we will see how to automate that with a dynamic provisioner

.footnote[¹Unbound = without an associated Persistent Volume.]

---

## If we have a dynamic provisioner ...

- The labs in this section assume that we *do not* have a dynamic provisioner

- If we do have one, we need to disable it

.exercise[

- Check if we have a dynamic provisioner:
  ```bash
  kubectl get storageclass
  ```

- If the output contains a line with `(default)`, run this command:
  ```bash
  kubectl annotate sc storageclass.kubernetes.io/is-default-class- --all
  ```

- Check again that it is no longer marked as `(default)`

]

---

## Deploying Consul

- Let's use a new manifest for our Consul cluster

- The only differences between that file and the previous one are:

  - `volumeClaimTemplate` defined in the Stateful Set spec

  - the corresponding `volumeMounts` in the Pod spec

.exercise[

- Apply the persistent Consul YAML file:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-3.yaml
  ```

]

---

## Observing the situation

- Let's look at Persistent Volume Claims and Pods

.exercise[

- Check that we now have an unbound Persistent Volume Claim:
  ```bash
  kubectl get pvc
  ```

- We don't have any Persistent Volume:
  ```bash
  kubectl get pv
  ```

- The Pod `consul-0` is not scheduled yet:
  ```bash
  kubectl get pods -o wide
  ```

]

*Hint: leave these commands running with `-w` in different windows.*

---

## Explanations

- In a Stateful Set, the Pods are started one by one

- `consul-1` won't be created until `consul-0` is running

- `consul-0` has a dependency on an unbound Persistent Volume Claim

- The scheduler won't schedule the Pod until the PVC is bound

  (because the PVC might be bound to a volume that is only available on a subset of nodes; for instance EBS are tied to an availability zone)

---

## Creating Persistent Volumes

- Let's create 3 local directories (`/mnt/consul`) on node2, node3, node4

- Then create 3 Persistent Volumes corresponding to these directories

.exercise[

- Create the local directories:
  ```bash
    for NODE in node2 node3 node4; do
      ssh $NODE sudo mkdir -p /mnt/consul
    done
  ```

- Create the PV objects:
  ```bash
  kubectl apply -f ~/container.training/k8s/volumes-for-consul.yaml
  ```

]

---

## Check our Consul cluster

- The PVs that we created will be automatically matched with the PVCs

- Once a PVC is bound, its pod can start normally

- Once the pod `consul-0` has started, `consul-1` can be created, etc.

- Eventually, our Consul cluster is up, and backend by "persistent" volumes

.exercise[

- Check that our Consul clusters has 3 members indeed:
  ```bash
  kubectl exec consul-0 -- consul members
  ```

]

---

## Devil is in the details (1/2)

- The size of the Persistent Volumes is bogus

  (it is used when matching PVs and PVCs together, but there is no actual quota or limit)

---

## Devil is in the details (2/2)

- This specific example worked because we had exactly 1 free PV per node:

  - if we had created multiple PVs per node ...

  - we could have ended with two PVCs bound to PVs on the same node ...

  - which would have required two pods to be on the same node ...

  - which is forbidden by the anti-affinity constraints in the StatefulSet

- To avoid that, we need to associated the PVs with a Storage Class that has:
  ```yaml
  volumeBindingMode: WaitForFirstConsumer
  ```
  (this means that a PVC will be bound to a PV only after being used by a Pod)

- See [this blog post](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/) for more details

---

## Bulk provisioning

- It's not practical to manually create directories and PVs for each app

- We *could* pre-provision a number of PVs across our fleet

- We could even automate that with a Daemon Set:

  - creating a number of directories on each node

  - creating the corresponding PV objects

- We also need to recycle volumes

- ... This can quickly get out of hand

---

## Dynamic provisioning

- We could also write our own provisioner, which would:

  - watch the PVCs across all namespaces

  - when a PVC is created, create a corresponding PV on a node

- Or we could use one of the dynamic provisioners for local persistent volumes

  (for instance the [Rancher local path provisioner](https://github.com/rancher/local-path-provisioner))

---

## Strategies for local persistent volumes

- Remember, when a node goes down, the volumes on that node become unavailable

- High availability will require another layer of replication

  (like what we've just seen with Consul; or primary/secondary; etc)

- Pre-provisioning PVs makes sense for machines with local storage

  (e.g. cloud instance storage; or storage directly attached to a physical machine)

- Dynamic provisioning makes sense for large number of applications

  (when we can't or won't dedicate a whole disk to a volume)

- It's possible to mix both (using distinct Storage Classes)

???

:EN:- Static vs dynamic volume provisioning
:EN:- Example: local persistent volume provisioner
:FR:- Création statique ou dynamique de volumes
:FR:- Exemple : création de volumes locaux
