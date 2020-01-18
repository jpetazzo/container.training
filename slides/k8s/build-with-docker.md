# Building images with the Docker Engine

- Until now, we have built our images manually, directly on a node

- We are going to show how to build images from within the cluster

  (by executing code in a container controlled by Kubernetes)

- We are going to use the Docker Engine for that purpose

- To access the Docker Engine, we will mount the Docker socket in our container

- After building the image, we will push it to our self-hosted registry

---

## Resource specification for our builder pod

.small[
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: build-image
spec:
  restartPolicy: OnFailure
  containers:
  - name: docker-build
    image: docker
    env:
    - name: REGISTRY_PORT
      value: "`3XXXX`"
    command: ["sh", "-c"]
    args:
    - |
      apk add --no-cache git &&
      mkdir /workspace &&
      git clone https://github.com/jpetazzo/container.training /workspace &&
      docker build -t localhost:$REGISTRY_PORT/worker /workspace/dockercoins/worker &&
      docker push localhost:$REGISTRY_PORT/worker
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
```
]

---

## Breaking down the pod specification (1/2)

- `restartPolicy: OnFailure` prevents the build from running in an infinite lopo

- We use the `docker` image (so that the `docker` CLI is available)

- We rely on the fact that the `docker` image is based on `alpine`

  (which is why we use `apk` to install `git`)

- The port for the registry is passed through an environment variable

  (this avoids repeating it in the specification, which would be error-prone)

.warning[The environment variable has to be a string, so the `"`s are mandatory!]

---

## Breaking down the pod specification (2/2)

- The volume `docker-socket` is declared with a `hostPath`, indicating a bind-mount

- It is then mounted in the container onto the default Docker socket path

- We show a interesting way to specify the commands to run in the container:

  - the command executed will be `sh -c <args>`

  - `args` is a list of strings

  - `|` is used to pass a multi-line string in the YAML file

---

## Running our pod

- Let's try this out!

.exercise[

- Check the port used by our self-hosted registry:
  ```bash
  kubectl get svc registry
  ```

- Edit `~/container.training/k8s/docker-build.yaml` to put the port number

- Schedule the pod by applying the resource file:
  ```bash
  kubectl apply -f ~/container.training/k8s/docker-build.yaml
  ```

- Watch the logs:
  ```bash
  stern build-image
  ```

<!--
```longwait latest: digest: sha256:```
```key ^C```
-->

]

---

## What's missing?

What do we need to change to make this production-ready?

- Build from a long-running container (e.g. a `Deployment`) triggered by web hooks

  (the payload of the web hook could indicate the repository to build)

- Build a specific branch or tag; tag image accordingly

- Handle repositories where the Dockerfile is not at the root

  (or containing multiple Dockerfiles)

- Expose build logs so that troubleshooting is straightforward

--

🤔 That seems like a lot of work!

--

That's why services like Docker Hub (with [automated builds](https://docs.docker.com/docker-hub/builds/)) are helpful.
<br/>
They handle the whole "code repository → Docker image" workflow.

---

## Things to be aware of

- This is talking directly to a node's Docker Engine to build images

- It bypasses resource allocation mechanisms used by Kubernetes

  (but you can use *taints* and *tolerations* to dedicate builder nodes)

- Be careful not to introduce conflicts when naming images

  (e.g. do not allow the user to specify the image names!)

- Your builds are going to be *fast*

  (because they will leverage Docker's caching system)
