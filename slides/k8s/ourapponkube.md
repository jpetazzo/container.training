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

## The plan

We are going to:

- **build** images for our app,

- **ship** these images with a registry,

- **run** deployments using these images,

- expose (with a ClusterIP) the deployments that need to communicate together,

- expose (with a NodePort) the web UI so we can access it from outside.

---

## Building and shipping our app

- We will pick a registry

  (let's pretend the address will be `REGISTRY:PORT`)

- We will build on our control node (`node1`)

  (the images will be named `REGISTRY:PORT/servicename`)

- We will push the images to the registry

- These images will be usable by the other nodes of the cluster

  (i.e., we could do `docker run REGISTRY:PORT/servicename` from these nodes)

---

## A shortcut opportunity

- As it happens, the images that we need do already exist on the Docker Hub:

  https://hub.docker.com/r/dockercoins/

- We could use them instead of using our own registry and images

*In the following slides, we are going to show how to run a registry
and use it to host container images. We will also show you how to
use the existing images from the Docker Hub, so that you can catch
up (or skip altogether the build/push part) if needed.*

---

## Which registry do we want to use?

- We could use the Docker Hub

- There are alternatives like Quay

- Each major cloud provider has an option as well

  (ACR on Azure, ECR on AWS, GCR on Google Cloud...)

- There are also commercial products to run our own registry

  (Docker EE, Quay...)

- And open source options, too!

*We are going to self-host an open source registry because it's the most generic solution for this workshop. We will use Docker's reference
implementation for simplicity.*

---

## Using the open source registry

- We need to run a `registry` container

- It will store images and layers to the local filesystem
  <br/>(but you can add a config file to use S3, Swift, etc.)

- Docker *requires* TLS when communicating with the registry

  - unless for registries on `127.0.0.0/8` (i.e. `localhost`)

  - or with the Engine flag `--insecure-registry`

- Our strategy: publish the registry container on a NodePort,
  <br/>so that it's available through `127.0.0.1:xxxxx` on each node

---

## Deploying a self-hosted registry

- We will deploy a registry container, and expose it with a NodePort

.exercise[

- Create the registry service:
  ```bash
  kubectl create deployment registry --image=registry
  ```

- Expose it on a NodePort:
  ```bash
  kubectl expose deploy/registry --port=5000 --type=NodePort
  ```

]

---

## Connecting to our registry

- We need to find out which port has been allocated

.exercise[

- View the service details:
  ```bash
  kubectl describe svc/registry
  ```

- Get the port number programmatically:
  ```bash
  NODEPORT=$(kubectl get svc/registry -o json | jq .spec.ports[0].nodePort)
  REGISTRY=127.0.0.1:$NODEPORT
  ```

]

---

## Testing our registry

- A convenient Docker registry API route to remember is `/v2/_catalog`

.exercise[

<!-- ```hide kubectl wait deploy/registry --for condition=available```-->

- View the repositories currently held in our registry:
  ```bash
  curl $REGISTRY/v2/_catalog
  ```

]

--

We should see:
```json
{"repositories":[]}
```

---

## Testing our local registry

- We can retag a small image, and push it to the registry

.exercise[

- Make sure we have the busybox image, and retag it:
  ```bash
  docker pull busybox
  docker tag busybox $REGISTRY/busybox
  ```

- Push it:
  ```bash
  docker push $REGISTRY/busybox
  ```

]

---

## Checking again what's on our local registry

- Let's use the same endpoint as before

.exercise[

- Ensure that our busybox image is now in the local registry:
  ```bash
  curl $REGISTRY/v2/_catalog
  ```

]

The curl command should now output:
```json
{"repositories":["busybox"]}
```

---

## Building and pushing our images

- We are going to use a convenient feature of Docker Compose

.exercise[

- Go to the `stacks` directory:
  ```bash
  cd ~/container.training/stacks
  ```

- Build and push the images:
  ```bash
  export REGISTRY
  export TAG=v0.1
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  ```

]

Let's have a look at the `dockercoins.yml` file while this is building and pushing.

---

```yaml
version: "3"

services:
  rng:
    build: dockercoins/rng
    image: ${REGISTRY-127.0.0.1:5000}/rng:${TAG-latest}
    deploy:
      mode: global
  ...
  redis:
    image: redis
  ...
  worker:
    build: dockercoins/worker
    image: ${REGISTRY-127.0.0.1:5000}/worker:${TAG-latest}
    ...
    deploy:
      replicas: 10
```

.warning[Just in case you were wondering ... Docker "services" are not Kubernetes "services".]

---

class: extra-details

## Avoiding the `latest` tag

.warning[Make sure that you've set the `TAG` variable properly!]

- If you don't, the tag will default to `latest`

- The problem with `latest`: nobody knows what it points to!

  - the latest commit in the repo?

  - the latest commit in some branch? (Which one?)

  - the latest tag?

  - some random version pushed by a random team member?

- If you keep pushing the `latest` tag, how do you roll back?

- Image tags should be meaningful, i.e. correspond to code branches, tags, or hashes

---

## Catching up

- If you have problems deploying the registry ...

- Or building or pushing the images ...

- Don't worry: you can easily use pre-built images from the Docker Hub!

- The images are named `dockercoins/worker:v0.1`, `dockercoins/rng:v0.1`, etc.

- To use them, just set the `REGISTRY` environment variable to `dockercoins`:
  ```bash
  export REGISTRY=dockercoins
  ```

- Make sure to set the `TAG` to `v0.1`

  (our repositories on the Docker Hub do not provide a `latest` tag)

---

# Running our application on Kubernetes

- We can now deploy our code (as well as a redis instance)

.exercise[

- Deploy `redis`:
  ```bash
  kubectl create deployment redis --image=redis
  ```

- Deploy everything else:
  ```bash
    for SERVICE in hasher rng webui worker; do
      kubectl create deployment $SERVICE --image=$REGISTRY/$SERVICE:$TAG
    done
  ```

]

---

## Is this working?

- After waiting for the deployment to complete, let's look at the logs!

  (Hint: use `kubectl get deploy -w` to watch deployment events)

.exercise[

<!-- ```hide
kubectl wait deploy/rng --for condition=available
kubectl wait deploy/worker --for condition=available
``` -->

- Look at some logs:
  ```bash
  kubectl logs deploy/rng
  kubectl logs deploy/worker
  ```

]

--

🤔 `rng` is fine ... But not `worker`.

--

💡 Oh right! We forgot to `expose`.

---

## Connecting containers together

- Three deployments need to be reachable by others: `hasher`, `redis`, `rng`

- `worker` doesn't need to be exposed

- `webui` will be dealt with later

.exercise[

- Expose each deployment, specifying the right port:
  ```bash
  kubectl expose deployment redis --port 6379
  kubectl expose deployment rng --port 80
  kubectl expose deployment hasher --port 80
  ```

]

---

## Is this working yet?

- The `worker` has an infinite loop, that retries 10 seconds after an error

.exercise[

- Stream the worker's logs:
  ```bash
  kubectl logs deploy/worker --follow
  ```

  (Give it about 10 seconds to recover)

<!--
```wait units of work done, updating hash counter```
```keys ^C```
-->

]

--

We should now see the `worker`, well, working happily.

---

## Exposing services for external access

- Now we would like to access the Web UI

- We will expose it with a `NodePort`

  (just like we did for the registry)

.exercise[

- Create a `NodePort` service for the Web UI:
  ```bash
  kubectl expose deploy/webui --type=NodePort --port=80
  ```

- Check the port that was allocated:
  ```bash
  kubectl get svc
  ```

]

---

## Accessing the web UI

- We can now connect to *any node*, on the allocated node port, to view the web UI

.exercise[

- Open the web UI in your browser (http://node-ip-address:3xxxx/)

<!-- ```open http://node1:3xxxx/``` -->

]

--

Yes, this may take a little while to update. *(Narrator: it was DNS.)*

--

*Alright, we're back to where we started, when we were running on a single node!*
