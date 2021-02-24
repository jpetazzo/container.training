# Shipping images with a registry

- Initially, our app was running on a single node

- We could *build* and *run* in the same place

- Therefore, we did not need to *ship* anything

- Now that we want to run on a cluster, things are different

- The easiest way to ship container images is to use a registry

---

## How Docker registries work (a reminder)

- What happens when we execute `docker run alpine` ?

- If the Engine needs to pull the `alpine` image, it expands it into `library/alpine`

- `library/alpine` is expanded into `index.docker.io/library/alpine`

- The Engine communicates with `index.docker.io` to retrieve `library/alpine:latest`

- To use something else than `index.docker.io`, we specify it in the image name

- Examples:
  ```bash
  docker pull gcr.io/google-containers/alpine-with-bash:1.0

  docker build -t registry.mycompany.io:5000/myimage:awesome .
  docker push registry.mycompany.io:5000/myimage:awesome
  ```

---

## Running DockerCoins on Kubernetes

- Create one deployment for each component

  (hasher, redis, rng, webui, worker)

- Expose deployments that need to accept connections

  (hasher, redis, rng, webui)

- For redis, we can use the official redis image

- For the 4 others, we need to build images and push them to some registry

---

## Building and shipping images

- There are *many* options!

- Manually:

  - build locally (with `docker build` or otherwise)

  - push to the registry

- Automatically:

  - build and test locally

  - when ready, commit and push a code repository

  - the code repository notifies an automated build system

  - that system gets the code, builds it, pushes the image to the registry

---

## Which registry do we want to use?

- There are SAAS products like Docker Hub, Quay ...

- Each major cloud provider has an option as well

  (ACR on Azure, ECR on AWS, GCR on Google Cloud...)

- There are also commercial products to run our own registry

  (Docker EE, Quay...)

- And open source options, too!

- When picking a registry, pay attention to its build system

  (when it has one)

---

## Building on the fly

- Conceptually, it is possible to build images on the fly from a repository

- Example: [ctr.run](https://ctr.run/)

  (deprecated in August 2020, after being aquired by Datadog)

- It did allow something like this:
  ```bash
  docker run ctr.run/github.com/jpetazzo/container.training/dockercoins/hasher
  ```

- No alternative yet

  (free startup idea, anyone?)

???

:EN:- Shipping images to Kubernetes
:FR:- Déployer des images sur notre cluster
