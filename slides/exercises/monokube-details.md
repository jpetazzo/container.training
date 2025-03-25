# Exercise — Monokube static pods

- We want to run a very basic Kubernetes cluster by starting only:

  - kubelet 

  - a container engine (e.g. Docker)

- The other components (control plane and otherwise) should be started with:

  - static pods

  - "classic" manifests loaded with e.g. `kubectl apply`

- This should be done with the "monokube" VM

  (which has Docker and kubelet 1.19 binaries available)

---

## Images to use

Here are some suggestions of images:

- etcd → `quay.io/coreos/etcd:vX.Y.Z`

- Kubernetes components → `registry.k8s.io/kube-XXX:vX.Y.Z`

  (where `XXX` = `apiserver`, `scheduler`, `controller-manager`)

To know which versions to use, check the version of the binaries installed on the `monokube` VM, and use the same ones.

See next slide for more hints!

---

## Inventory

We'll need to run:

- kubelet (with the flag for static pod manifests)

- Docker

- static pods for control plane components

  (suggestion: use `hostNetwork`)

- static pod or DaemonSet for `kube-proxy`

  (will require a privileged security context)
