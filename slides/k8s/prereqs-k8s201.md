# Pre-requirements

- Kubernetes concepts

  (pods, deployments, services, labels, selectors)

- Hands-on experience working with containers

  (building images, running them; doesn't matter how exactly)

- Familiar with the UNIX command-line

  (navigating directories, editing files, using `kubectl`)

---

## Labs and exercises

- We are going to explore advanced k8s concepts

- Everyone will get their own private environment

- You are invited to reproduce all the demos (but you don't have to)

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!

- Go to @@SLIDES@@ to view these slides

<!-- ```open @@SLIDES@@``` -->

]

---

## Private environments

- Each person gets their own Kubernetes cluster

- Each person should have a printed card with connection information

- We will connect to these clusters with `kubectl`

  (if you don't have `kubectl` installed, install it **now!**)

---

## Doing or re-doing this on your own?

- We are using AKS with kubectl installed locally

- You could use any managed k8s

- You could also use any cloud VMs with Ubuntu LTS and Kubernetes [packages] or [binaries] installed

[packages]: https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

[binaries]: https://kubernetes.io/docs/setup/release/notes/#server-binaries
