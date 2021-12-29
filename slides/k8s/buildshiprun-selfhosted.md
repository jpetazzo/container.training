## Self-hosting our registry

*Note: this section shows how to run the Docker
open source registry and use it to ship images
on our cluster. While this method works fine,
we recommend that you consider using one of the
hosted, free automated build services instead.
It will be much easier!*

*If you need to run a registry on premises,
this section gives you a starting point, but
you will need to make a lot of changes so that
the registry is secured, highly available, and
so that your build pipeline is automated.*

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

.lab[

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

.lab[

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

.lab[

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

.lab[

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

.lab[

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

.lab[

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

## Checking the content of the registry

- All our images should now be in the registry

.lab[

- Re-run the same `curl` command as earlier:
  ```bash
  curl $REGISTRY/v2/_catalog
  ```

]

*In these slides, all the commands to deploy
DockerCoins will use a $REGISTRY environment
variable, so that we can quickly switch from
the self-hosted registry to pre-built images
hosted on the Docker Hub. So make sure that
this $REGISTRY variable is set correctly when
running these commands!*