# Registries

- There are lots of options to ship our container images to a registry

- We can group them depending on some characteristics:

- SaaS or self-hosted

- with or without a build system

---

## Docker registry

- Self-hosted and [open source](https://github.com/docker/distribution)

- Runs in a single Docker container

- Supports multiple storage backends

- Supports basic authentication out of the box

- [Other authentication schemes](https://docs.docker.com/registry/deploying/#more-advanced-authentication) through proxy or delegation

- No build system

- To run it with the Docker engine:

  ```shell
  docker run -d -p 5000:5000 --name registry registry:2
  ```

- Or use the dedicated plugin in minikube, microk8s, etc.

---

## Harbor

- Self-hostend and [open source](https://github.com/goharbor/harbor)

- Supports both Docker images and Helm charts

- Advanced authentification mechanism

- Multi-site synchronisation

- Vulnerability scanning

- No build system

- To run it with Helm:
  ```shell
  helm repo add harbor https://helm.goharbor.io
  helm install my-release harbor/harbor
  ```

---

## Gitlab

- Available both as a SaaS product and self-hosted

- SaaS product is free for open source projects; paid subscription otherwise

- Some parts are [open source](https://gitlab.com/gitlab-org/gitlab-foss/)

- Integrated CI

- No build system (but a custom build system can be hooked to the CI)

- To run it with Helm:
  ```shell
  helm repo add gitlab https://charts.gitlab.io/
  helm install gitlab gitlab/gitlab
  ```

---

## Docker Hub

- SaaS product: [hub.docker.com](https://hub.docker.com)

- Free for public image; paid subscription for private ones

- Build system included

---

## Quay

- Available both as a SaaS product (Quay) and self-hosted ([quay.io](https://quay.io))

- SaaS product is free for public repositories; paid subscription otherwise

- Some components of Quay and quay.io are open source

  (see [Project Quay](https://www.projectquay.io/) and the [announcement](https://www.redhat.com/en/blog/red-hat-introduces-open-source-project-quay-container-registry))

- Build system included
