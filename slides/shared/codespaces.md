# Codespaces

- We're going to use GitHub Codespaces to get a Docker/Kubernetes lab

- This can take a few minutes (because of image builds, downloads...)

- Let's do it now, so that it's ready when we'll need it!

---

## Creating a codespace

- Click on [that link][codespaces-new] then click `Create codespace`

  (feel free to pick a region closer to you!)

- Another way to create the codespace:

  - go to https://github.com/jpetazzo/container.training

  - click on the green `<> Code v` button

  - click on the green `Create codespace on main` button

- If you use an IDE that supports devcontainers, you can also use that instead

  (example: VScode; but today, please just use codespaces for simplicity :))

[codespaces-new]: https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=37004081&skip_quickstart=true

---

## Troubleshooting

- If it takes more than a couple of minutes or says "Oh no, it looks like you are offline":

  disable "enhanced tracking protection" and/or uBlock origin and reload the page

---

## KinD

- The Codespaces environment runs Docker, and is loaded with many tools

- We still need to create a Kubernetes cluster

- We're going to use KinD to do that

  (but we could also use minikube, k3d...)

.lab[

- Create a Kubernetes cluster with KinD:
  ```bash
  kind create cluster
  ```

]

- Note: if you have a machine running [Docker][install-docker] or [Podman][install-podman], you can [install KinD][install-kind] and then run `kind create cluster`!

[install-docker]: https://www.docker.com/get-started/
[install-podman]: https://podman.io/get-started
[install-kind]: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries

---

## Checking that our cluster works

- One of the most basic commands we can do is to list the nodes of the cluster

  (with KinD, by default, we get a cluster with one single node)

.lab[

- List the nodes (well, the node) of the cluster:
  ```bash
  kubectl get nodes
  ```

]

- If you deployed the cluster with KinD, you can also run `docker ps`

  (what do we see?)

---

## Dev clusters vs "real" clusters

- With KinD, minikube, and other dev clusters, we can:

  - run containers on a one-node cluster

  - use Kubernetes tools like `kubectl`, `k9s`, `helm`, and many more
  
  - create all kinds of Kubernetes resources (Deployments, Services...)

  - install operators, webhooks, and all sorts of Kubernetes extensions

  - deploy things like Prometheus, Grafana, Argo, Flux

  - we can even prototype persistent applications (databases, queues...)

- So, what *cannot* we do?

---

## Limitations

- We cannot expose containers to the outside world like we'd do on a normal cluster

  (e.g. with a *`LoadBalancer Service`*)

- It's running on our local machine

  (so we're limited in terms of RAM, CPU, storage...)

- Our dev cluster typically has a single node

  (making it harder to experiment with DaemonSets, taints, tolerations, affinity...)

- Metrics might be off

  (since the cluster isn't the only thing running on the machine)
