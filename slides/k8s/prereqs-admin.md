# Pre-requirements

- Kubernetes concepts

  (pods, deployments, services, labels, selectors)

- Hands-on experience working with containers

  (building images, running them; doesn't matter how exactly)

- Familiar with the UNIX command-line

  (navigating directories, editing files, using `kubectl`)

---

## Labs and exercises

- We are going to build and break multiple clusters

- Everyone will get their own private environment(s)

- You are invited to reproduce all the demos (but you don't have to)

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!

- Go to @@SLIDES@@ to view these slides

<!-- ```open @@SLIDES@@``` -->

]

---

## Private environments

- Each person gets their own private set of VMs

- Each person should have a printed card with connection information

- We will connect to these VMs with SSH

  (if you don't have an SSH client, install one **now!**)

---

## Doing or re-doing this on your own?

- We are using basic cloud VMs with Ubuntu LTS

- Kubernetes [packages] or [binaries] have been installed

  (depending on what we want to accomplish in the lab)

- We disabled IP address checks

  - we want to route pod traffic directly between nodes

  - most cloud providers will treat pod IP addresses as invalid

  - ... and filter them out; so we disable that filter

[packages]: https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

[binaries]: https://kubernetes.io/docs/setup/release/notes/#server-binaries
