## Build, tag, and push our container images

- Compose has named our images `dockercoins_XXX` for each service

- We need to retag them (to `127.0.0.1:5000/XXX:v1`) and push them

.lab[

- Set `REGISTRY` and `TAG` environment variables to use our local registry
- And run this little for loop:
  ```bash
    cd ~/container.training/dockercoins
    export REGISTRY=127.0.0.1:5000
    export TAG=v0.1
    for SERVICE in hasher rng webui worker; do
      docker build -t $REGISTRY/$SERVICE:$TAG ./$SERVICE
      docker push $REGISTRY/$SERVICE:$TAG
    done
  ```

]

---

## Overlay networks

- SwarmKit integrates with overlay networks

- Networks are created with `docker network create`

- Make sure to specify that you want an *overlay* network
  <br/>(otherwise you will get a local *bridge* network by default)

.lab[

- Create an overlay network for our application:
  ```bash
  docker network create --driver overlay dockercoins
  ```

]

---

## Viewing existing networks

- Let's confirm that our network was created

.lab[

- List existing networks:
  ```bash
  docker network ls
  ```

]

---

## Can you spot the differences?

The networks `dockercoins` and `ingress` are different from the other ones.

Can you see how?

--


- They are using a different kind of ID, reflecting the fact that they
  are SwarmKit objects instead of "classic" Docker Engine objects.

- Their *scope* is `swarm` instead of `local`.

- They are using the overlay driver.

---

class: extra-details

## Caveats

.warning[In Docker 1.12, you cannot join an overlay network with `docker run --net ...`.]

Starting with version 1.13, you can, if the network was created with the `--attachable` flag.

*Why is that?*

Placing a container on a network requires allocating an IP address for this container.

The allocation must be done by a manager node (worker nodes cannot update Raft data).

As a result, `docker run --net ...` requires collaboration with manager nodes.

It alters the code path for `docker run`, so it is allowed only under strict circumstances.

---

## Run the application

- First, create the `redis` service; that one is using a Docker Hub image

.lab[

- Create the `redis` service:
  ```bash
  docker service create --network dockercoins --name redis redis
  ```

]

---

## Run the other services

- Then, start the other services one by one

- We will use the images pushed previously

.lab[

- Start the other services:
  ```bash
    export REGISTRY=127.0.0.1:5000
    export TAG=v0.1
    for SERVICE in hasher rng webui worker; do
      docker service create --network dockercoins --detach=true \
        --name $SERVICE $REGISTRY/$SERVICE:$TAG
    done
  ```

]

---

## Expose our application web UI

- We need to connect to the `webui` service, but it is not publishing any port

- Let's reconfigure it to publish a port

.lab[

- Update `webui` so that we can connect to it from outside:
  ```bash
  docker service update webui --publish-add 8000:80
  ```

]

Note: to "de-publish" a port, you would have to specify the container port.
</br>(i.e. in that case, `--publish-rm 80`)

---

## What happens when we modify a service?

- Let's find out what happened to our `webui` service

.lab[

- Look at the tasks and containers associated to `webui`:
  ```bash
  docker service ps webui
  ```
]

--

The first version of the service (the one that was not exposed) has been shutdown.

It has been replaced by the new version, with port 80 accessible from outside.

(This will be discussed with more details in the section about stateful services.)

---

## Connect to the web UI

- The web UI is now available on port 8000, *on all the nodes of the cluster*

.lab[

- If you're using Play-With-Docker, just click on the `(8000)` badge

- Otherwise, point your browser to any node, on port 8000

]

---

## Scaling the application

- We can change scaling parameters with `docker update` as well

- We will do the equivalent of `docker-compose scale`

.lab[

- Bring up more workers:
  ```bash
  docker service update worker --replicas 10
  ```

- Check the result in the web UI

]

You should see the performance peaking at 10 hashes/s (like before).

---

# Global scheduling

- We want to utilize as best as we can the entropy generators
  on our nodes

- We want to run exactly one `rng` instance per node

- SwarmKit has a special scheduling mode for that, let's use it

- We cannot enable/disable global scheduling on an existing service

- We have to destroy and re-create the `rng` service

---

## Scaling the `rng` service

.lab[

- Remove the existing `rng` service:
  ```bash
  docker service rm rng
  ```

- Re-create the `rng` service with *global scheduling*:
  ```bash
    docker service create --name rng --network dockercoins --mode global \
      $REGISTRY/rng:$TAG
  ```

- Look at the result in the web UI

]

---

class: extra-details

## Why do we have to re-create the service?

- State reconciliation is handled by a *controller*

- The controller knows how to "converge" a scaled service spec to another

- It doesn't know how to "transform" a scaled service into a global one
  <br/>
  (or vice versa)

- This might change in the future (after all, it was possible in 1.12 RC!)

- As of Docker Engine 18.03, other parameters requiring to `rm`/`create` the service are:

  - service name

  - hostname

---

## Removing everything

- Before moving on, let's get a clean slate

.lab[

- Remove *all* the services:
  ```bash
  docker service ls -q | xargs docker service rm
  ```

]
