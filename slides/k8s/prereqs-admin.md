# Additional lab environments

- We will now use new sets of VMs

- Look out for new individual cards with connection information!

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
