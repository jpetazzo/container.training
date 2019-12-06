# container super-structure (Pods)

A container super-structure supported by many container engine seems to emerge,
we will see how it maps in the docker worlds



---
class: pic

## Pod

![Pods](images/kubernetes_pods.svg)
---
# Anatomy of a Pod

- The containers inside a pod share the network namespace (`--net=container:<container_id>`)

   => the one of the "pause" containers

- This means that if the container "pause" is killed all other container are killed

- This is the reason for this container to do nothing but being alive

- Containers can contact other container port via `localhost`

- Containers don't share filesystem except the volumes you want to mount on each of them
