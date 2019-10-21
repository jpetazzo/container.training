## Get Kubernetes

- In order to do the other labs and exercises, we need a Kubernetes cluster

- Here are some *free* options:

  - Docker Desktop

  - Minikube

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

## Recommendation 3: hosted cluster

- You can also get your own hosted cluster

- This will cost a little bit of money

  (unless you have free hosting credits)

- Setup will vary depending on the provider, platform, etc.

