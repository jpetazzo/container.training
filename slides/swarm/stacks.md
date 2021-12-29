class: btp-manual

## Integration with Compose

- We saw how to manually build, tag, and push images to a registry

- But ...

--

class: btp-manual

*"I'm so glad that my deployment relies on ten nautic miles of Shell scripts"*

*(No-one, ever)*

--

class: btp-manual

- Let's see how we can streamline this process!

---

# Swarm Stacks

- Compose is great for local development

- It can also be used to manage image lifecycle

  (i.e. build images and push them to a registry)

- Compose files *v2* are great for local development

- Compose files *v3* can also be used for production deployments!

---

## Compose file version 3

(New in Docker Engine 1.13)

- Almost identical to version 2

- Can be directly used by a Swarm cluster through `docker stack ...` commands

- Introduces a `deploy` section to pass Swarm-specific parameters

- Resource limits are moved to this `deploy` section

- See [here](https://github.com/docker/docker.github.io/blob/master/compose/compose-file/compose-versioning.md#upgrading) for the complete list of changes

- Supersedes *Distributed Application Bundles*

  (JSON payload describing an application; could be generated from a Compose file)

---

## Our first stack

We need a registry to move images around.

Without a stack file, it would be deployed with the following command:

```bash
docker service create --publish 5000:5000 registry
```

Now, we are going to deploy it with the following stack file:

```yaml
version: "3"

services:
  registry:
    image: registry
    ports:
      - "5000:5000"
```

---

## Checking our stack files

- All the stack files that we will use are in the `stacks` directory

.lab[

- Go to the `stacks` directory:
  ```bash
  cd ~/container.training/stacks
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

.lab[

- Deploy our local registry:
  ```bash
  docker stack deploy --compose-file registry.yml registry
  ```

]

---

## Inspecting stacks

- `docker stack ps` shows the detailed state of all services of a stack

.lab[

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

class: btp-manual

## Specifics of stack deployment

Our registry is not *exactly* identical to the one deployed with `docker service create`!

- Each stack gets its own overlay network

- Services of the stack are connected to this network
  <br/>(unless specified differently in the Compose file)

- Services get network aliases matching their name in the Compose file
  <br/>(just like when Compose brings up an app specified in a v2 file)

- Services are explicitly named `<stack_name>_<service_name>`

- Services and tasks also get an internal label indicating which stack they belong to

---

class: btp-auto

## Testing our local registry

- Connecting to port 5000 *on any node of the cluster* routes us to the registry

- Therefore, we can use `localhost:5000` or `127.0.0.1:5000` as our registry

.lab[

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

class: btp-auto

## Pushing an image to our local registry

- We can retag a small image, and push it to the registry

.lab[

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

class: btp-auto

## Checking what's on our local registry

- The registry API has endpoints to query what's there

.lab[

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

.lab[

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

.lab[

- Create the application stack:
  ```bash
  docker stack deploy --compose-file dockercoins.yml dockercoins
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

- Further versions (3.1, ...) add more features (secrets, configs ...)

- You can re-run `docker stack deploy` to update a stack

- You can make manual changes with `docker service update` ...

- ... But they will be wiped out each time you `docker stack deploy`

  (That's the intended behavior, when one thinks about it!)

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
