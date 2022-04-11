# Tilt

- What does a development workflow look like?

  - make changes

  - test / see these changes

  - repeat!

- What does it look like, with containers?

  🤔

---

## Basic Docker workflow

- Preparation

  - write Dockerfiles

- Iteration

  - edit code
  - `docker build`
  - `docker run`
  - test
  - `docker stop`

Straightforward when we have a single container.

---

## Docker workflow with volumes

- Preparation

  - write Dockerfiles
  - `docker build` + `docker run`

- Iteration

  - edit code
  - test

Note: only works with interpreted languages.
<br/>
(Compiled languages require extra work.)

---

## Docker workflow with Compose

- Preparation

  - write Dockerfiles + Compose file
  - `docker-compose up`

- Iteration

  - edit code
  - test
  - `docker-compose up` (as needed)

Simplifies complex scenarios (multiple containers).
<br/>
Facilitates updating images.

---

## Basic Kubernetes workflow

- Preparation

  - write Dockerfiles
  - write Kubernetes YAML
  - set up container registry

- Iteration

  - edit code
  - build images
  - push images
  - update Kubernetes resources

Seems simple enough, right?

---

## Basic Kubernetes workflow

- Preparation

  - write Dockerfiles
  - write Kubernetes YAML
  - **set up container registry**

- Iteration

  - edit code
  - build images
  - **push images**
  - update Kubernetes resources

Ah, right ...

---

## We need a registry

- Remember "build, ship, and run"

- Registries are involved in the "ship" phase

- With Docker, we were building and running on the same node

- We didn't need a registry!

- With Kubernetes, though ...

---

## Special case of single node clusters

- If our Kubernetes has only one node ...

- ... We can build directly on that node ...

- ... We don't need to push images ...

- ... We don't need to run a registry!

- Examples: Docker Desktop, Minikube ...

---

## When we have more than one node

- Which registry should we use?

  (Docker Hub, Quay, cloud-based, self-hosted ...)

- Should we use a single registry, or one per cluster or environment?

- Which tags and credentials should we use?

  (in particular when using a shared registry!)

- How do we provision that registry and its users?

- How do we adjust our Kubernetes YAML manifests?

  (e.g. to inject image names and tags)

---

## More questions

- The whole cycle (build+push+update) is expensive

- If we have many services, how do we update only the ones we need?

- Can we take shortcuts?

  (e.g. synchronized files without going through a whole build+push+update cycle)

---

## Tilt

- Tilt is a tool to address all these questions

- There are other similar tools (e.g. Skaffold)

- We arbitrarily decided to focus on that one

---

## Tilt in practice

- The `dockercoins` directory in our repository has a `Tiltfile`

- That Tiltfile includes definitions for the DockerCoins app, including:

  - building the images for the app

  - Kubernetes manifests to deploy the app

  - a self-hosted registry to host the app image

- Let's try it out!

---

## Running Tilt locally

*These instructions are valid only if you run Tilt on your local machine.*

*If you are running Tilt on a remote machine or in a Pod, see next slide.*

- Start Tilt:
  ```bash
  tilt up
  ```

- Then press "space" or connect to http://localhost:10350/

---

## Running Tilt on a remote machine

- If Tilt runs remotely, we can't access `http://localhost:10350`

- We'll need to tell Tilt to listen to `0.0.0.0`

  (instead of just `localhost`)

- If we run Tilt in a Pod, we need to expose port 10350 somehow

  (and Tilt needs to listen on `0.0.0.0`, too)

---

## Telling Tilt to listen in `0.0.0.0`

- This can be done with the `--host` flag:
  ```bash
  tilt --host=0.0.0.0
  ```

- Or by setting the `TILT_HOST` environment variable:
  ```bash
  export TILT_HOST=0.0.0.0
  tilt up
  ```

---

## Running Tilt in a Pod

If you use `shpod`, you can use the following command:

```bash
kubectl patch service shpod --namespace shpod -p "
spec:
  ports:
  - name: tilt
    port: 10350
    targetPort: 10350
    nodePort: 30150
    protocol: TCP
"
```

Then connect to port 30150 on any of your nodes.

If you use something else than `shpod`, adapt these instructions!

---
class: extra-details

## Kubernetes contexts

- Tilt is designed to run in dev environments

- It will try to figure out if we're really in a dev environment:

  - if Tilt thinks that are on a local dev cluster, it will start

  - otherwise, it will give us a warning and it won't continue

- In the latter case, we need to add one line to the Tiltfile

  (to tell Tilt "it's okay, you can run safely in this environment!")

- If this happens, add the line to the Tiltfile

  (Tilt will tell you exactly what to add!)

- We don't need to restart Tilt, it will detect the change immediately

---

## What's in our Tiltfile?

- Kubernetes manifests for a local registry

- Kubernetes manifests for DockerCoins

- Instructions indicating how to build DockerCoins' images

- A tiny bit of sugar

  (telling Tilt which registry to use)

---


## How does it work?

- Tilt keeps track of dependencies between files and resources

  (a bit like a `make` that would run continuously)

- It automatically alters some resources

  (for instance, it updates the images used in our Kubernetes manifests)

- That's it!

(And of course, it provides a great web UI, lots of libraries, etc.)

---

## What happens when we edit a file (1/2)

- Let's change e.g. `worker/worker.py`

- Thanks to this line,
  ```python
  docker_build('dockercoins/worker', 'worker')
  ```
  ... Tilt watches the `worker` directory and uses it to build `dockercoins/worker`

- Thanks to this line,
  ```python
  default_registry('localhost:30555')
  ```
  ... Tilt actually renames `dockercoins/worker` to `localhost:30555/dockercoins_worker`

- Tilt will tag the image with something like `tilt-xxxxxxxxxx`

---

## What happens when we edit a file (2/2)

- Thanks to this line,
  ```python
  k8s_yaml('../k8s/dockercoins.yaml')
  ```
  ... Tilt is aware of our Kubernetes resources

- The `worker` Deployment uses `dockercoins/worker`, so it must be updated

- `dockercoins/worker` becomes `localhost:30555/dockercoins_worker:tilt-xxx`

- The `worker` Deployment gets updated on the Kubernetes cluster

- All these operations (and their log output) are visible in the Tilt UI

---

## Configuration file format

- The Tiltfile is written in [Starlark](https://github.com/bazelbuild/starlark)

  (essentially a subset of Python)

- Tilt monitors the Tiltfile too

  (so it reloads it immediately when we change it)

---

## Tilt "killer features"

- Dependency engine

  (build or run only what's necessary)

- Ability to watch resources

  (execute actions immediately, without explicitly running a command)

- Rich library of function and helpers

  (build container images, manipulate YAML manifests...)

- Convenient UI (web; TUI also available)

  (provides immediate feedback and logs)

- Extensibility!

???

:EN:- Development workflow with Tilt
:FR:- Développer avec Tilt
