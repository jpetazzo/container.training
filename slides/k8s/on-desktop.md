# Development Workflow

In this section we will see how to set up a local development workflow.

We will list multiple options.

Keep in mind that we don't have to use *all* these tools!

It's up to the developer to find what best suits them.

---

## What does it mean to develop on Kubernetes ?

In theory, the generic workflow is:

1. Make changes to our code or edit a Dockerfile

2. Build a new Docker image with a new tag

3. Push that Docker image to a registry

4. Update the YAML or templates referencing that Docker image
   <br/>(e.g. of the corresponding Deployment, StatefulSet, Job ...)

5. Apply the YAML or templates

6. Are we satisfied with the result?
   <br/>No → go back to step 1 (or step 4 if the image is OK)
   <br/>Yes → commit and push our changes to source control

---

## A few quirks

In practice, there are some details that make this workflow more complex.

- We need a Docker container registry to store our images
  <br/>
  (for Open Source projects, a free Docker Hub account works fine)

- We need to set image tags properly, hopefully automatically

- If we decide to use a fixed tag (like `:latest`) instead:

  - we need to specify `imagePullPolicy=Always` to force image pull

  - we need to trigger a rollout when we want to deploy a new image
    <br/>(with `kubectl rollout restart` or by killing the running pods)

- We need a fast internet connection to push the images

- We need to regularly clean up the registry to avoid accumulating old images

---

## When developing locally

- If we work with a local cluster, pushes and pulls are much faster

- Even better, with a one-node cluster, most of these problems disappear

- If we build and run the images on the same node, ...

  - we don't need to push images

  - we don't need a fast internet connection

  - we don't need a registry

  - we can use bind mounts to edit code locally and make changes available immediately in running containers

- This means that it is much simpler to deploy to local development environment (like Minikube, Docker Desktop ...) than to a "real" cluster

---

## Minikube

- Start a VM with the hypervisor of your choice: VirtualBox, kvm, Hyper-V ...

- Well supported by the Kubernetes community

- Lot of addons

- Easy cleanup: delete the VM with `minikube delete`

- Bind mounts depend on the underlying hypervisor

  (they may require additionnal setup)

---

## Docker Desktop

- Available for Mac and Windows

- Start a VM with the appropriate hypervisor (even better!)

- Bind mounts work out of the box

```yaml
volumes:
- name: repo_dir
  hostPath:
    path: /C/Users/Enix/my_code_repository
```

- Ingress and other addons need to be installed manually

---

## Kind

- Kubernetes-in-Docker

- Uses Docker-in-Docker to run Kubernetes
  <br/>
  (technically, it's more like Containerd-in-Docker)

- We don't get a real Docker Engine (and cannot build Dockerfiles)

- Single-node by default, but multi-node clusters are possible

- Very convenient to test Kubernetes deployments when only Docker is available
  <br/>
  (e.g. on public CI services like Travis, Circle, GitHub Actions ...)

- Bind mounts require extra configuration

- Extra configuration for a couple of addons, totally custom for other

- Doesn't work with BTRFS (sorry BTRFS users😢)

---

## microk8s

- Distribution of Kubernetes using Snap

  (Snap is a container-like method to install software)

- Available on Ubuntu and derivatives

- Bind mounts work natively (but require extra setup if we run in a VM)

- Big list of addons; easy to install

---

## Proper tooling

The simple workflow seems to be:

- set up a one-node cluster with one of the methods mentioned previously,

- find the remote Docker endpoint,

- configure the `DOCKER_HOST` variable to use that endpoint,

- follow the previous 7-step workflow.

Can we do better?

---

## Helpers

- Skaffold (https://skaffold.dev/):
    - build with docker, kaniko, google builder
    - install with pure yaml manifests, kustomize, helm

- Tilt (https://tilt.dev/)
    - Tiltfile is programmatic format (python ?)
    - Primitive for building with docker
    - Primitive for deploying with pure yaml manifests, kustomize, helm

- Garden (https://garden.io/)

- Forge (https://forge.sh/)
