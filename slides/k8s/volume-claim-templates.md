## Putting it all together

- We want to run that Consul cluster *and* actually persist data

- We'll use a StatefulSet that will leverage PV and PVC

- If we have a dynamic provisioner:

  *the cluster will come up right away*

- If we don't have a dynamic provisioner:

  *we will need to create Persistent Volumes manually*

---

## Persistent Volume Claims and Stateful sets

- A Stateful set can define one (or more) `volumeClaimTemplate`

- Each `volumeClaimTemplate` will create one Persistent Volume Claim per Pod

- Each Pod will therefore have its own individual volume

- These volumes are numbered (like the Pods)

- Example:

  - a Stateful set is named `consul`
  - it is scaled to replicas
  - it has a `volumeClaimTemplate` named `data`
  - then it will create pods `consul-0`, `consul-1`, `consul-2`
  - these pods will have volumes named `data`, referencing PersistentVolumeClaims
    named `data-consul-0`, `data-consul-1`, `data-consul-2`

---

## Persistent Volume Claims are sticky

- When updating the stateful set (e.g. image upgrade), each pod keeps its volume

- When pods get rescheduled (e.g. node failure), they keep their volume

  (this requires a storage system that is not node-local)

- These volumes are not automatically deleted

  (when the stateful set is scaled down or deleted)

- If a stateful set is scaled back up later, the pods get their data back

---

## Deploying Consul

- Let's use a new manifest for our Consul cluster

- The only differences between that file and the previous one are:

  - `volumeClaimTemplate` defined in the Stateful Set spec

  - the corresponding `volumeMounts` in the Pod spec

.lab[

- Apply the persistent Consul YAML file:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-3.yaml
  ```

]

---

## No dynamic provisioner

- If we don't have a dynamic provisioner, we need to create the PVs

- We are going to use local volumes

  (similar conceptually to `hostPath` volumes)

- We can use local volumes without installing extra plugins

- However, they are tied to a node

- If that node goes down, the volume becomes unavailable

---

## Observing the situation

- Let's look at Persistent Volume Claims and Pods

.lab[

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

.lab[

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

.lab[

- Check that our Consul clusters has 3 members indeed:
  ```bash
  kubectl exec consul-0 -- consul members
  ```

]

---

## Devil is in the details (1/2)

- The size of the Persistent Volumes is bogus

  (it is used when matching PVs and PVCs together, but there is no actual quota or limit)

- The Pod might end up using more than the requested size

- The PV may or may not have the capacity that it's advertising

- It works well with dynamically provisioned block volumes

- ...Less so in other scenarios!

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

## If we have a dynamic provisioner

These are the steps when dynamic provisioning happens:

1. The Stateful Set creates PVCs according to the `volumeClaimTemplate`.

2. The Stateful Set creates Pods using these PVCs.

3. The PVCs are automatically annotated with our Storage Class.

4. The dynamic provisioner provisions volumes and creates the corresponding PVs.

5. The PersistentVolumeClaimBinder associates the PVs and the PVCs together.

6. PVCs are now bound, the Pods can start.

---

## Validating persistence (1)

- When the StatefulSet is deleted, the PVC and PV still exist

- And if we recreate an identical StatefulSet, the PVC and PV are reused

- Let's see that!

.lab[

- Put some data in Consul:
  ```bash
  kubectl exec consul-0 -- consul kv put answer 42
  ```

- Delete the Consul cluster:
  ```bash
  kubectl delete -f ~/container.training/k8s/consul-3.yaml
  ```

]

---

## Validating persistence (2)

.lab[

- Wait until the last Pod is deleted:
  ```bash
  kubectl wait pod consul-0 --for=delete
  ```

- Check that PV and PVC are still here:
  ```bash
  kubectl get pv,pvc
  ```

]

---

## Validating persistence (3)

.lab[

- Re-create the cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul-3.yaml
  ```

- Wait until it's up

- Then access the key that we set earlier:
  ```bash
  kubectl exec consul-0 -- consul kv get answer
  ```

]

---

## Cleaning up

- PV and PVC don't get deleted automatically

- This is great (less risk of accidental data loss)

- This is not great (storage usage increases)

- Managing PVC lifecycle:

  - remove them manually

  - add their StatefulSet to their `ownerReferences`

  - delete the Namespace that they belong to

???

:EN:- Defining volumeClaimTemplates
:FR:- Définir des volumeClaimTemplates
