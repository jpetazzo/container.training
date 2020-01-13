# Registries

There is lot of options to ship you container image to a registry

Those can be group in different categories:

- hosted / selfhosted

- with / without build system

---
## Docker registry

- [open-source](https://github.com/docker/distribution) and self-hosted

- Simple docker-based registry

- Support multiple storage backend

- Only support basic-authentification

- No build system

```shell
docker run -d -p 5000:5000 --name registry registry:2
```
or the dedicated plugin in minikube, microk8s, ...

---
## Harbor

- [open-source](https://github.com/goharbor/harbor) and self-hosted

- full-featured registry docker/helm registry

- advanced authentification mechanism

- multi-site synchronisation

- vulnerability scanning

- No build-system

```shell
helm repo add harbor https://helm.goharbor.io
helm install my-release harbor/harbor
```

---
## Gitlab

- Some part [open-source](https://gitlab.com/gitlab-org/gitlab-foss/) and self-hosted

- Or hosted: gitlab.com (free for opensource project, payed subscription otherwise)

- CI integrated (so in a way: build-system integrated)

```shell
helm repo add gitlab https://charts.gitlab.io/
helm install gitlab gitlab/gitlab
```

---
## Docker HUB

- hosted: [hub.docker.com](https://hub.docker.com)

- free for public image, payed subscription for private ones.

- build-system included

---
## Quay

- hosted (quay.io)[https://quay.io]

- free for public repository, payed subscription otherwise

- acquired by Redhat from CoreOS, opensourced recently (so self-hosted to ?)

- build-system included
