## Privileged container

- Running privileged container could be really harmful for the node it run on.

- Getting control of a node could expose other containers in the cluster and the cluster itself

- It's even worse when it is docker that run in this privileged container

- `docker build` doesn't allow to run privileged container for building layer

- nothing forbid to run `docker run --privileged`

---
## Kaniko

- https://github.com/GoogleContainerTools/kaniko

- *kaniko doesn't depend on a Docker daemon and executes each command
within a Dockerfile completely in userspace*

- Kaniko is only a build system, there is no runtime like docker does

- generates OCI compatible image, so could be run on Docker or other CRI

- use a different cache system than Docker

---
## Rootless docker and rootless buildkit

- This is experimental

- Have a lot of requirement of kernel param, options to set

- But it exists
