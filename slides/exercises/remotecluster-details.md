# Exercise — Remote Cluster

- We want to control a remote cluster

- Then we want to run a copy of dockercoins on that cluster

- We want to be able to connect to an internal service

---

## Goal

- Be able to access e.g. hasher, rng, or webui

  (without exposing them with a NodePort or LoadBalancer service)

---

## Getting access to the cluster

- If you don't have `kubectl` on your machine, install it

- Download the kubeconfig file from the remote cluster

  (you can use `scp` or even copy-paste it)

- If you already have a kubeconfig file on your machine:

  - save the remote kubeconfig with another name (e.g. `~/.kube/config.remote`)

  - set the `KUBECONFIG` environment variable to point to that file name

  - ...or use the `--kubeconfig=...` option with `kubectl`

- Check that you can access the cluster (e.g. `kubectl get nodes`)

---

## If you get an error...

⚠️ The following applies to clusters deployed with `kubeadm`

- If you have a cluster where the nodes are named `node1`, `node2`, etc.

- `kubectl` commands might show connection errors with internal IP addresses

  (e.g. 10.10... or 172.17...)

- In that case, you might need to edit the `kubeconfig` file:

  - find the server address

  - update it to put the *external* address of the first node of the cluster

---


## Deploying an app

- Deploy another copy of dockercoins from your local machine

- Access internal services (e.g. with `kubectl port-forward`)
