class: title

Our app on Swarm

---

## What's on the menu?

In this part, we will:

- **build** images for our app,

- **ship** these images with a registry,

- **run** services using these images.

---

## Why do we need to ship our images?

- When we do `docker-compose up`, images are built for our services

- These images are present only on the local node

- We need these images to be distributed on the whole Swarm

- The easiest way to achieve that is to use a Docker registry

- Once our images are on a registry, we can reference them when
  creating our services

---

class: extra-details

## Build, ship, and run, for a single service

If we had only one service (built from a `Dockerfile` in the
current directory), our workflow could look like this:

```
docker build -t jpetazzo/doublerainbow:v0.1 .
docker push jpetazzo/doublerainbow:v0.1
docker service create jpetazzo/doublerainbow:v0.1
```

We just have to adapt this to our application, which has 4 services!

---

## The plan

- Build on our local node (`node1`)

- Tag images so that they are named `localhost:5000/servicename`

- Upload them to a registry

- Create services using the images

---

## Which registry do we want to use?

.small[

- **Docker Hub**

  - hosted by Docker Inc.
  - requires an account (free, no credit card needed)
  - images will be public (unless you pay)
  - located in AWS EC2 us-east-1

- **Docker Trusted Registry**

  - self-hosted commercial product
  - requires a subscription (free 30-day trial available)
  - images can be public or private
  - located wherever you want

- **Docker open source registry**

  - self-hosted barebones repository hosting
  - doesn't require anything
  - doesn't come with anything either
  - located wherever you want

]

---

class: extra-details

## Using Docker Hub

*If we wanted to use the Docker Hub...*

<!--
```meta
^{
```
-->

- We would log into the Docker Hub:
  ```bash
  docker login
  ```

- And in the following slides, we would use our Docker Hub login
  (e.g. `jpetazzo`) instead of the registry address (i.e. `127.0.0.1:5000`)

<!--
```meta
^}
```
-->

---

class: extra-details

## Using Docker Trusted Registry

*If we wanted to use DTR, we would...*

- Make sure we have a Docker Hub account

- [Activate a Docker Datacenter subscription](
  https://hub.docker.com/enterprise/trial/)

- Install DTR on our machines

- Use `dtraddress:port/user` instead of the registry address

*This is out of the scope of this workshop!*

---

## Using the open source registry

- We need to run a `registry:2` container
  <br/>(make sure you specify tag `:2` to run the new version!)

- It will store images and layers to the local filesystem
  <br/>(but you can add a config file to use S3, Swift, etc.)

- Docker *requires* TLS when communicating with the registry

  - unless for registries on `127.0.0.0/8` (i.e. `localhost`)

  - or with the Engine flag `--insecure-registry`

<!-- -->

- Our strategy: publish the registry container on port 5000,
  <br/>so that it's available through `127.0.0.1:5000` on each node

---

class: manual-btp

# Deploying a local registry

- We will create a single-instance service, publishing its port
  on the whole cluster

.exercise[

- Create the registry service:
  ```bash
  docker service create --name registry --publish 5000:5000 registry:2
  ```

- Try the following command, until it returns `{"repositories":[]}`:
  ```bash
  curl 127.0.0.1:5000/v2/_catalog
  ```

]

(Retry a few times, it might take 10-20 seconds for the container to be started. Patience.)

---

class: manual-btp

## Testing our local registry

- We can retag a small image, and push it to the registry

.exercise[

- Make sure we have the busybox image, and retag it:
  ```bash
  docker pull busybox
  docker tag busybox 127.0.0.1:5000/busybox
  ```

- Push it:
  ```bash
  docker push 127.0.0.1:5000/busybox
  ```

]

---

class: manual-btp

## Checking what's on our local registry

- The registry API has endpoints to query what's there

.exercise[

- Ensure that our busybox image is now in the local registry:
  ```bash
  curl http://127.0.0.1:5000/v2/_catalog
  ```

]

The curl command should now output:
```json
{"repositories":["busybox"]}
```

---

class: manual-btp

## Build, tag, and push our application container images

- Compose has named our images `dockercoins_XXX` for each service

- We need to retag them (to `127.0.0.1:5000/XXX:v1`) and push them

.exercise[

- Set `REGISTRY` and `TAG` environment variables to use our local registry
- And run this little for loop:
  ```bash
    cd ~/orchestration-workshop/dockercoins
    REGISTRY=127.0.0.1:5000 TAG=v1
    for SERVICE in hasher rng webui worker; do
      docker tag dockercoins_$SERVICE $REGISTRY/$SERVICE:$TAG
      docker push $REGISTRY/$SERVICE
    done
  ```

]

---

class: manual-btp

# Overlay networks

- SwarmKit integrates with overlay networks

- Networks are created with `docker network create`

- Make sure to specify that you want an *overlay* network
  <br/>(otherwise you will get a local *bridge* network by default)

.exercise[

- Create an overlay network for our application:
  ```bash
  docker network create --driver overlay dockercoins
  ```

]

---

class: manual-btp

## Viewing existing networks

- Let's confirm that our network was created

.exercise[

- List existing networks:
  ```bash
  docker network ls
  ```

]

---

class: manual-btp

## Can you spot the differences?

The networks `dockercoins` and `ingress` are different from the other ones.

Can you see how?

--

class: manual-btp

- They are using a different kind of ID, reflecting the fact that they
  are SwarmKit objects instead of "classic" Docker Engine objects.

- Their *scope* is `swarm` instead of `local`.

- They are using the overlay driver.

---

class: manual-btp, extra-details

## Caveats

.warning[In Docker 1.12, you cannot join an overlay network with `docker run --net ...`.]

Starting with version 1.13, you can, if the network was created with the `--attachable` flag.

*Why is that?*

Placing a container on a network requires allocating an IP address for this container.

The allocation must be done by a manager node (worker nodes cannot update Raft data).

As a result, `docker run --net ...` requires collaboration with manager nodes.

It alters the code path for `docker run`, so it is allowed only under strict circumstances.

---

class: manual-btp

## Run the application

- First, create the `redis` service; that one is using a Docker Hub image

.exercise[

- Create the `redis` service:
  ```bash
  docker service create --network dockercoins --name redis redis
  ```

]

---

class: manual-btp

## Run the other services

- Then, start the other services one by one

- We will use the images pushed previously

.exercise[

- Start the other services:
  ```bash
  REGISTRY=127.0.0.1:5000
  TAG=v1
  for SERVICE in hasher rng webui worker; do
    docker service create --network dockercoins --detach=true \
           --name $SERVICE $REGISTRY/$SERVICE:$TAG
  done
  ```

]

???

## Wait for our application to be up

- We will see later a way to watch progress for all the tasks of the cluster

- But for now, a scrappy Shell loop will do the trick

.exercise[

- Repeatedly display the status of all our services:
  ```bash
  watch "docker service ls -q | xargs -n1 docker service ps"
  ```

- Stop it once everything is running

]

---

class: manual-btp

## Expose our application web UI

- We need to connect to the `webui` service, but it is not publishing any port

- Let's reconfigure it to publish a port

.exercise[

- Update `webui` so that we can connect to it from outside:
  ```bash
  docker service update webui --publish-add 8000:80 --detach=false
  ```

]

Note: to "de-publish" a port, you would have to specify the container port.
</br>(i.e. in that case, `--publish-rm 80`)

---

class: manual-btp

## What happens when we modify a service?

- Let's find out what happened to our `webui` service

.exercise[

- Look at the tasks and containers associated to `webui`:
  ```bash
  docker service ps webui
  ```
]

--

class: manual-btp

The first version of the service (the one that was not exposed) has been shutdown.

It has been replaced by the new version, with port 80 accessible from outside.

(This will be discussed with more details in the section about stateful services.)

---

class: manual-btp

## Connect to the web UI

- The web UI is now available on port 8000, *on all the nodes of the cluster*

.exercise[

- If you're using Play-With-Docker, just click on the `(8000)` badge

- Otherwise, point your browser to any node, on port 8000

]

---

## Scaling the application

- We can change scaling parameters with `docker update` as well

- We will do the equivalent of `docker-compose scale`

.exercise[

- Bring up more workers:
  ```bash
  docker service update worker --replicas 10 --detach=false
  ```

- Check the result in the web UI

]

You should see the performance peaking at 10 hashes/s (like before).

---

class: manual-btp

# Global scheduling

- We want to utilize as best as we can the entropy generators
  on our nodes

- We want to run exactly one `rng` instance per node

- SwarmKit has a special scheduling mode for that, let's use it

- We cannot enable/disable global scheduling on an existing service

- We have to destroy and re-create the `rng` service

---

class: manual-btp

## Scaling the `rng` service

.exercise[

- Remove the existing `rng` service:
  ```bash
  docker service rm rng
  ```

- Re-create the `rng` service with *global scheduling*:
  ```bash
    docker service create --name rng --network dockercoins --mode global \
      --detach=false $REGISTRY/rng:$TAG
  ```

- Look at the result in the web UI

]

---

class: extra-details, manual-btp

## Why do we have to re-create the service to enable global scheduling?

- Enabling it dynamically would make rolling updates semantics very complex

- This might change in the future (after all, it was possible in 1.12 RC!)

- As of Docker Engine 17.05, other parameters requiring to `rm`/`create` the service are:

  - service name

  - hostname

  - network

---

class: swarm-ready

## How did we make our app "Swarm-ready"?

This app was written in June 2015. (One year before Swarm mode was released.)

What did we change to make it compatible with Swarm mode?

--

.exercise[

- Go to the app directory:
  ```bash
  cd ~/orchestration-workshop/dockercoins
  ```

- See modifications in the code:
  ```bash
  git log -p --since "4-JUL-2015" -- . ':!*.yml*' ':!*.html'
  ```

]

---

class: swarm-ready

## What did we change in our app since its inception?

- Compose files

- HTML file (it contains an embedded contextual tweet)

- Dockerfiles (to switch to smaller images)

- That's it!

--

class: swarm-ready

*We didn't change a single line of code in this app since it was written.*

--

class: swarm-ready

*The images that were [built in June 2015](
https://hub.docker.com/r/jpetazzo/dockercoins_worker/tags/)
(when the app was written) can still run today ...
<br/>... in Swarm mode (distributed across a cluster, with load balancing) ...
<br/>... without any modification.*

---

class: swarm-ready

## How did we design our app in the first place?

- [Twelve-Factor App](https://12factor.net/) principles

- Service discovery using DNS names

  - Initially implemented as "links"

  - Then "ambassadors"

  - And now "services"

- Existing apps might require more changes!

---

class: manual-btp

# Integration with Compose

- The previous section showed us how to streamline image build and push

- We will now see how to streamline service creation

  (i.e. get rid of the `for SERVICE in ...; do docker service create ...` part)

---

## Compose file version 3

(New in Docker Engine 1.13)

- Almost identical to version 2

- Can be directly used by a Swarm cluster through `docker stack ...` commands

- Introduces a `deploy` section to pass Swarm-specific parameters

- Resource limits are moved to this `deploy` section

- See [here](https://github.com/aanand/docker.github.io/blob/8524552f99e5b58452fcb1403e1c273385988b71/compose/compose-file.md#upgrading) for the complete list of changes

- Supersedes *Distributed Application Bundles*

  (JSON payload describing an application; could be generated from a Compose file)

---

class: manual-btp

## Removing everything

- Before deploying using "stacks," let's get a clean slate

.exercise[

- Remove *all* the services:
  ```bash
  docker service ls -q | xargs docker service rm
  ```

]

---

## Our first stack

We need a registry to move images around.

Without a stack file, it would be deployed with the following command:

```bash
docker service create --publish 5000:5000 registry:2
```

Now, we are going to deploy it with the following stack file:

```yaml
version: "3"

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
```

---

## Checking our stack files

- All the stack files that we will use are in the `stacks` directory

.exercise[

- Go to the `stacks` directory:
  ```bash
  cd ~/orchestration-workshop/stacks
  ```

- Check `registry.yml`:
  ```bash
  cat registry.yml
  ```

]

---

## Deploying our first stack

- All stack manipulation commands start with `docker stack`

- Under the hood, they map to `docker service` commands

- Stacks have a *name* (which also serves as a namespace)

- Stacks are specified with the aforementioned Compose file format version 3

.exercise[

- Deploy our local registry:
  ```bash
  docker stack deploy registry --compose-file registry.yml
  ```

]

---

## Inspecting stacks

- `docker stack ps` shows the detailed state of all services of a stack

.exercise[

- Check that our registry is running correctly:
  ```bash
  docker stack ps registry
  ```

- Confirm that we get the same output with the following command:
  ```bash
  docker service ps registry_registry
  ```

]

---

class: manual-btp

## Specifics of stack deployment

Our registry is not *exactly* identical to the one deployed with `docker service create`!

- Each stack gets its own overlay network

- Services of the task are connected to this network
  <br/>(unless specified differently in the Compose file)

- Services get network aliases matching their name in the Compose file
  <br/>(just like when Compose brings up an app specified in a v2 file)

- Services are explicitly named `<stack_name>_<service_name>`

- Services and tasks also get an internal label indicating which stack they belong to

---

class: auto-btp

## Testing our local registry

- Connecting to port 5000 *on any node of the cluster* routes us to the registry

- Therefore, we can use `localhost:5000` or `127.0.0.1:5000` as our registry

.exercise[

- Issue the following API request to the registry:
  ```bash
  curl 127.0.0.1:5000/v2/_catalog
  ```

]

It should return:

```json
{"repositories":[]}
```

If that doesn't work, retry a few times; perhaps the container is still starting.

---

class: auto-btp

## Pushing an image to our local registry

- We can retag a small image, and push it to the registry

.exercise[

- Make sure we have the busybox image, and retag it:
  ```bash
  docker pull busybox
  docker tag busybox 127.0.0.1:5000/busybox
  ```

- Push it:
  ```bash
  docker push 127.0.0.1:5000/busybox
  ```

]

---

class: auto-btp

## Checking what's on our local registry

- The registry API has endpoints to query what's there

.exercise[

- Ensure that our busybox image is now in the local registry:
  ```bash
  curl http://127.0.0.1:5000/v2/_catalog
  ```

]

The curl command should now output:
```json
"repositories":["busybox"]}
```

---

## Building and pushing stack services

- When using Compose file version 2 and above, you can specify *both* `build` and `image`

- When both keys are present:

  - Compose does "business as usual" (uses `build`)

  - but the resulting image is named as indicated by the `image` key
    <br/>
    (instead of `<projectname>_<servicename>:latest`)

  - it can be pushed to a registry with `docker-compose push`

- Example:

  ```yaml
    webfront:
      build: www
      image: myregistry.company.net:5000/webfront
  ```

---

## Using Compose to build and push images

.exercise[

- Try it:
  ```bash
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

---

## Deploying the application

- Now that the images are on the registry, we can deploy our application stack

.exercise[

- Create the application stack:
  ```bash
  docker stack deploy dockercoins --compose-file dockercoins.yml
  ```

]

We can now connect to any of our nodes on port 8000, and we will see the familiar hashing speed graph.

---

## Maintaining multiple environments

There are many ways to handle variations between environments.

- Compose loads `docker-compose.yml` and (if it exists) `docker-compose.override.yml`

- Compose can load alternate file(s) by setting the `-f` flag or the `COMPOSE_FILE` environment variable

- Compose files can *extend* other Compose files, selectively including services:

  ```yaml
    web:
      extends:
        file: common-services.yml
        service: webapp
  ```

See [this documentation page](https://docs.docker.com/compose/extends/) for more details about these techniques.


---

class: extra-details

## Good to know ...

- Compose file version 3 adds the `deploy` section

- Compose file version 3.1 adds support for secrets

- You can re-run `docker stack deploy` to update a stack

- ... But unsupported features will be wiped each time you redeploy (!)

  (This will likely be fixed/improved soon)

- `extends` doesn't work with `docker stack deploy`

  (But you can use `docker-compose config` to "flatten" your configuration)

---

## Summary

- We've seen how to set up a Swarm

- We've used it to host our own registry

- We've built our app container images

- We've used the registry to host those images

- We've deployed and scaled our application

- We've seen how to use Compose to streamline deployments

- Awesome job, team!
