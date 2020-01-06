# Development Workflow

In this section we will see how to get started with local development workflow,

We will list multiple options, yet not all tools are mandatory.

It's up to the developer to find what's best suit him/her.

---
## What does it mean to develop on kubernetes ?

The generic workflow is:

- (1) Change code or Dockerfile in one repository

- (2) Build the docker image with a new tag

- (3) Push the docker image to a registry

- (4) Edit the yamls/templates corresponding to the deployment of the docker image

- (5) Apply the yamls/templates

- (6) Check if you're satisfied, if no repeat from 1 (or 4 if image is ok)

- (7) Commit and push

---
## A few quirks

Looking more precisely to the workflow, it's quite complicated

- Need to have docker container registry that the cluster can access.

    (If you work a opensource project then a free account on DockerHub could just work)

- Need scripting new tag creation

- or use `imagePullPolicy=Always` to force image pull, then kill the appropriate pods

- Require high broadband bandwidth and lot of time to push lot of images

- Requires a registry's clean-up phase to avoid messy situations of left-over tags

---
## Benefits with developping locally

Some of those problem could be solved using a local one-node cluster:

- Using the node itself to build the image avoid pushing over network

- No need of a registry

  or use a local-registry inside the cluster to avoid requiring broadband access

- Can use bind mounts to make code change directly available in containers

---

## Minikube

- start a VM with the hypervisor of your choice: virtualbox, kvm, hyperv, ...

- well supported by the kubernetes community

- lot of addons

- easy cleanup: delete the VM ! (`minikube delete`)

- Bind mounts depends on the underlying hypervisor, and may require additionnal setup

---
## Docker-for-Mac/Windows

- start a VM with the appropriate hypervisor (even better !)

- bind mount works out of the box

```yaml
volumes:
- name: repo_dir
  hostPath:
    path: /C/Users/Enix/my_code_repository
```

- ingress and other addons need to be installed manualy

---
## Kind

- Use docker-in-docker to run kubernetes

- It's actually more "containerd-in-docker" than real "d-in-d"

   So building "Dockerfile" is not a option

- Able to simulate multiple nodes

→ Kind is quite handy to test kubernetes deployments on Public CI (Travis/Circle)
   where only docker is available

- Extra configuration for bind mount

- Extra configuration for a couple of addons, totally custom for other

- Warning brtfs user: that doesn't work 😢

---
## microk8s

- snap(container like) distribution of kubernetes

- work on: Ubuntu and derivative, or Ubuntu VM

- big list of addons easy to install

- bind mount work natively, need extra setup if you use a VM

---
## Proper tooling

We ran our neat one-node-cluster. What do we do now ?

- find the remote docker endpoint and export the DOCKER_HOST variable

- follow the previous 7-steps workflow

Can we do better ?
---
## Skaffold


Note: Draft and Forge are softwares with some functional overlap
