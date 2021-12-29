# Building images with Kaniko

- [Kaniko](https://github.com/GoogleContainerTools/kaniko) is an open source tool to build container images within Kubernetes

- It can build an image using any standard Dockerfile

- The resulting image can be pushed to a registry or exported as a tarball

- It doesn't require any particular privilege

  (and can therefore run in a regular container in a regular pod)

- This combination of features is pretty unique

  (most other tools use different formats, or require elevated privileges)

---

## Kaniko in practice

- Kaniko provides an "executor image", `gcr.io/kaniko-project/executor`

- When running that image, we need to specify at least:

  - the path to the build context (=the directory with our Dockerfile)

  - the target image name (including the registry address)

- Simplified example:
  ```
  docker run \
      -v ...:/workspace gcr.io/kaniko-project/executor \
      --context=/workspace \
      --destination=registry:5000/image_name:image_tag
  ```

---

## Running Kaniko in a Docker container

- Let's build the image for the DockerCoins `worker` service with Kaniko

.lab[

- Find the port number for our self-hosted registry:
  ```bash
  kubectl get svc registry
  PORT=$(kubectl get svc registry -o json | jq .spec.ports[0].nodePort)
  ```

- Run Kaniko:
  ```bash
  docker run --net host \
      -v ~/container.training/dockercoins/worker:/workspace \
      gcr.io/kaniko-project/executor \
      --context=/workspace \
      --destination=127.0.0.1:$PORT/worker-kaniko:latest 
  ```

]

We use `--net host` so that we can connect to the registry over `127.0.0.1`.

---

## Running Kaniko in a Kubernetes pod

- We need to mount or copy the build context to the pod

- We are going to build straight from the git repository

  (to avoid depending on files sitting on a node, outside of containers)

- We need to `git clone` the repository before running Kaniko

- We are going to use two containers sharing a volume:

  - a first container to `git clone` the repository to the volume

  - a second container to run Kaniko, using the content of the volume

- However, we need the first container to be done before running the second one

🤔 How could we do that?

---

## [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to the rescue

- A pod can have a list of `initContainers`

- `initContainers` are executed in the specified order

- Each Init Container needs to complete (exit) successfully

- If any Init Container fails (non-zero exit status) the pod fails

  (what happens next depends on the pod's `restartPolicy`)

- After all Init Containers have run successfully, normal `containers` are started

- We are going to execute the `git clone` operation in an Init Container

---

## Our Kaniko builder pod

.small[
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kaniko-build
spec:
  initContainers:
  - name: git-clone
    image: alpine
    command: ["sh", "-c"]
    args: 
    - |
      apk add --no-cache git &&
      git clone git://github.com/jpetazzo/container.training /workspace
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  containers:
  - name: build-image
    image: gcr.io/kaniko-project/executor:latest
    args:
      - "--context=/workspace/dockercoins/rng"
      - "--insecure"
      - "--destination=registry:5000/rng-kaniko:latest"
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  volumes:
  - name: workspace
```
]

---

## Explanations

- We define a volume named `workspace` (using the default `emptyDir` provider)

- That volume is mounted to `/workspace` in both our containers

- The `git-clone` Init Container installs `git` and runs `git clone`

- The `build-image` container executes Kaniko

- We use our self-hosted registry DNS name (`registry`)

- We add `--insecure` to use plain HTTP to talk to the registry

---

## Running our Kaniko builder pod

- The YAML for the pod is in `k8s/kaniko-build.yaml`

.lab[

- Create the pod:
  ```bash
  kubectl apply -f ~/container.training/k8s/kaniko-build.yaml
  ```

- Watch the logs:
  ```bash
  stern kaniko
  ```

<!--
```longwait registry:5000/rng-kaniko:latest:```
```key ^C```
-->

]

---

## Discussion

*What should we use? The Docker build technique shown earlier? Kaniko? Something else?*

- The Docker build technique is simple, and has the potential to be very fast

- However, it doesn't play nice with Kubernetes resource limits

- Kaniko plays nice with resource limits

- However, it's slower (there is no caching at all)

- The ultimate building tool will probably be [Jessica Frazelle](https://twitter.com/jessfraz)'s [img](https://github.com/genuinetools/img) builder

  (it depends on upstream changes that are not in Kubernetes 1.11.2 yet)

But ... is it all about [speed](https://github.com/AkihiroSuda/buildbench/issues/1)? (No!)

---

## The big picture

- For starters: the [Docker Hub automated builds](https://docs.docker.com/docker-hub/builds/) are very easy to set up

  - link a GitHub repository with the Docker Hub

  - each time you push to GitHub, an image gets build on the Docker Hub

- If this doesn't work for you: why?

  - too slow (I'm far from `us-east-1`!) → consider using your cloud provider's registry

  - I'm not using a cloud provider → ok, perhaps you need to self-host then

  - I need fancy features (e.g. CI) → consider something like GitLab
