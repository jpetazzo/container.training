## Assignment: get Kubernetes

- In order to do the other assignments, we need a Kubernetes cluster

- Here are some *free* options:

  - Docker Desktop

  - Minikube

  - Online sandbox like Katacoda

- You can also get a managed cluster (but this costs some money)

---

## Recommendation 1: Docker Desktop

- If you are already using Docker Desktop, use it for Kubernetes

- If you are running MacOS, [install Docker Desktop](https://docs.docker.com/docker-for-mac/install/)

  - you will need a post-2010 Mac

  - you will need macOS Sierra 10.12 or later

- If you are running Windows 10, [install Docker Desktop](https://docs.docker.com/docker-for-windows/install/)

  - you will need Windows 10 64 bits Pro, Enterprise, or Education

  - virtualization needs to be enabled in your BIOS

- Then [enable Kubernetes](https://blog.docker.com/2018/07/kubernetes-is-now-available-in-docker-desktop-stable-channel/) if it's not already on

---

## Recommendation 2: Minikube

- In some scenarios, you can't use Docker Desktop:

  - if you run Linux

  - if you are running an unsupported version of Windows

- You might also want to install Minikube for other reasons

  (there are more tutorials and instructions out there for Minikube)

- Minikube installation is a bit more complex

  (depending on which hypervisor and OS you are using)

---

## Minikube installation details

- Minikube typically runs in a local virtual machine

- It supports multiple hypervisors:

  - VirtualBox (Linux, Mac, Windows)

  - HyperV (Windows)

  - HyperKit, VMware (Mac)

  - KVM (Linux)

- Check the [documentation](https://kubernetes.io/docs/tasks/tools/install-minikube/) for details relevant to your setup

---

## Recommendation 3: learning platform

- Sometimes, you can't even install Minikube

  (computer locked by IT policies; insufficient resources...)

- In that case, you can use a platform like:

  - Katacoda

  - Play-with-Kubernetes

---

## Recommendation 4: hosted cluster

- You can also get your own hosted cluster

- This will cost a little bit of money

  (unless you have free hosting credits)

- Setup will vary depending on the provider, platform, etc.

---

class: assignment

- Make sure that you have a Kubernetes cluster

- You should be able to run `kubectl get nodes` and see a list of nodes

- These nodes should be in `Ready` state
