# Exercise — networking

- We want to install extra networking components:

  - a CNI configuration

  - kube-proxy

  - CoreDNS

- After doing that, we should be able to deploy a "complex" app

  (with multiple containers communicating together + service discovery)

---

## CNI

- Easy option: Weave

  https://github.com/weaveworks/weave/releases

- Better option: Cilium

  https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli

  or https://docs.cilium.io/en/stable/installation/k8s-install-helm/#installation-using-helm

---

## kube-proxy

- Option 1: author a DaemonSet

- Option 2: leverage the CNI (some CNIs like Cilium can replace kube-proxy)

---

## CoreDNS

- Suggested method: Helm chart

  (available on https://github.com/coredns/helm)

---

## Testing

- Try to deploy DockerCoins and confirm that it works

  (for instance with [this YAML file](https://raw.githubusercontent.com/jpetazzo/container.training/refs/heads/main/k8s/dockercoins.yaml))
