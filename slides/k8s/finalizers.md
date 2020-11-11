# Finalizers

- Sometimes, we.red[¹] want to prevent a resource from being deleted:

  - perhaps it's "precious" (holds important data)

  - perhaps other resources depend on it (and should be deleted first)

  - perhaps we need to perform some clean up before it's deleted

- *Finalizers* are a way to do that!

.footnote[.red[¹]The "we" in that sentence generally stands for a controller.
<br/>(We can also use finalizers directly ourselves, but it's not very common.)]

---

## Examples

- Prevent deletion of a PersistentVolumeClaim which is used by a Pod

- Prevent deletion of a PersistentVolume which is bound to a PersistentVolumeClaim

- Prevent deletion of a Namespace that still contains objects

- When a LoadBalancer Service is deleted, make sure that the corresponding external resource (e.g. NLB, GLB, etc.) gets deleted.red[¹]

- When a CRD gets deleted, make sure that all the associated resources get deleted.red[²]

.footnote[.red[¹²]Finalizers are not the only solution for these use-cases.]

---

## How do they work?

- Each resource can have list of `finalizers` in its `metadata`, e.g.:

  ```yaml
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: my-pvc
      annotations: ...
      finalizers:
      - kubernetes.io/pvc-protection
  ```

- If we try to delete an resource that has at least one finalizer:

  - the resource is *not* deleted

  - instead, its `deletionTimestamp` is set to the current time

  - we are merely *marking the resource for deletion*

---

## What happens next?

- The controller that added the finalizer is supposed to:

  - watch for resources with a `deletionTimestamp`

  - execute necessary clean-up actions

  - then remove the finalizer

- The resource is deleted once all the finalizers have been removed

  (there is no timeout, so this could take forever)

- Until then, the resource can be used normally

  (but no further finalizer can be *added* to the resource)

---

## Finalizers in review

Let's review the examples mentioned earlier.

For each of them, we'll see if there are other (perhaps better) options.

---

## Volume finalizer

- Kubernetes applies the following finalizers:

  - `kubernetes.io/pvc-protection` on PersistentVolumeClaims

  - `kubernetes.io/pv-protection` on PersistentVolumes

- This prevents removing them when they are in use

- Implementation detail: the finalizer is present *even when the resource is not in use*

- When the resource is ~~deleted~~ marked for deletion, the controller will check if the finalizer can be removed

  (Perhaps to avoid race conditions?)

---

## Namespace finalizer

- Kubernetes applies a finalizer named `kubernetes`

- It prevents removing the namespace if it still contains objects

- *Can we remove the namespace anyway?*

  - remove the finalizer

  - delete the namespace

  - force deletion

- It *seems to works* but, in fact, the objects in the namespace still exist

  (and they will re-appear if we re-create the namespace)

See [this blog post](https://www.openshift.com/blog/the-hidden-dangers-of-terminating-namespaces) for more details about this.

---

## LoadBalancer finalizer

- Scenario:

  We run a custom controller to implement provisioning of LoadBalancer Services.

  When a Service with type=LoadBalancer is deleted, we want to make sure
  that the corresponding external resources are properly deleted.

- Rationale for using a finalizer:

  Normally, we would watch and observe the deletion of the Service;
  but if the Service is deleted while our controller is down,
  we could "miss" the deletion and forget to clean up the external resource.

  The finalizer ensures that we will "see" the deletion
  and clean up the external resource.

---

## Counterpoint

- We could also:

  - Tag the external resources
    <br/>(to indicate which Kubernetes Service they correspond to)

  - Periodically reconcile them against Kubernetes resources

  - If a Kubernetes resource does no longer exist, delete the external resource

- This doesn't have to be a *pre-delete* hook

  (unless we store important information in the Service, e.g. as annotations)

---

## CRD finalizer

- Scenario:

  We have a CRD that represents a PostgreSQL cluster.

  It provisions StatefulSets, Deployments, Services, Secrets, ConfigMaps.

  When the CRD is deleted, we want to delete all these resources.

- Rationale for using a finalizer:

  Same as previously; we could observe the CRD, but if it is deleted
  while the controller isn't running, we would miss the deletion,
  and the other resources would keep running.

---

## Counterpoint

- We could use the same technique as described before

  (tag the resources with e.g. annotations, to associate them with the CRD)

- Even better: we could use `ownerReferences`

  (this feature is *specifically* designed for that use-case!)

---

## CRD finalizer (take two)

- Scenario:

  We have a CRD that represents a PostgreSQL cluster.

  It provisions StatefulSets, Deployments, Services, Secrets, ConfigMaps.

  When the CRD is deleted, we want to delete all these resources.

  We also want to store a final backup of the database.

  We also want to update final usage metrics (e.g. for billing purposes).

- Rationale for using a finalizer:

  We need to take some actions *before* the resources get deleted, not *after*.

---

## Wrapping up

- Finalizers are a great way to:

  - prevent deletion of a resource that is still in use

  - have a "guaranteed" pre-delete hook

- They can also be (ab)used for other purposes

- Code spelunking exercise:

  *check where finalizers are used in the Kubernetes code base and why!*

???

:EN:- Using "finalizers" to manage resource lifecycle
:FR:- Gérer le cycle de vie des ressources avec les *finalizers*
