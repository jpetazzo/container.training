# Container Super-structure

- Multiple orchestration platforms support some kind of container super-structure.

  (i.e., a construct or abstraction bigger than a single container.)

- For instance, on Kubernetes, this super-structure is called a *pod*.

- A pod is a group of containers (it could be a single container, too).

- These containers run together, on the same host.

  (A pod cannot straddle multiple hosts.)

- All the containers in a pod have the same IP address.

- How does that map to the Docker world?

---

class: pic

## Anatomy of a Pod

![Pods](images/kubernetes_pods.svg)

---

## Pods in Docker

- The containers inside a pod share the same network namespace.

  (Just like when using `docker run --net=container:<container_id>` with the CLI.)

- As a result, they can communicate together over `localhost`.

- In addition to "our" containers, the pod has a special container, the *sandbox*.

- That container uses a special image: `k8s.gcr.io/pause`.

  (This is visible when listing containers running on a Kubernetes node.)

- Containers within a pod have independent filesystems.

- They can share directories by using a mechanism called *volumes.*

  (Which is similar to the concept of volumes in Docker.)
