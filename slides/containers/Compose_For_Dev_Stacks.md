# Compose for development stacks

Dockerfile = great to build *one* container image.

What if we have multiple containers?

What if some of them require particular `docker run` parameters?

How do we connect them all together?

... Compose solves these use-cases (and a few more).

---

## Life before Compose

Before we had Compose, we would typically write custom scripts to:

- build container images,

- run containers using these images,

- connect the containers together,

- rebuild, restart, update these images and containers.

---

## Life with Compose

Compose enables a simple, powerful onboarding workflow:

1. Checkout our code.

2. Run `docker-compose up`.

3. Our app is up and running!

---

class: pic

![composeup](images/composeup.gif)

---

## Life after Compose

(Or: when do we need something else?)

- Compose is *not* an orchestrator

- It isn't designed to need to run containers on multiple nodes

  (it can, however, work with Docker Swarm Mode)

- Compose isn't ideal if we want to run containers on Kubernetes

  - it uses different concepts (Compose services ≠ Kubernetes services)

  - it needs a Docker Engine (althought containerd support might be coming)

---

## First rodeo with Compose

1. Write Dockerfiles

2. Describe our stack of containers in a YAML file called `docker-compose.yml`

3. `docker-compose up` (or `docker-compose up -d` to run in the background)

4. Compose pulls and builds the required images, and starts the containers

5. Compose shows the combined logs of all the containers

   (if running in the background, use `docker-compose logs`)

6. Hit Ctrl-C to stop the whole stack

   (if running in the background, use `docker-compose stop`)

---

## Iterating

After making changes to our source code, we can:

1. `docker-compose build` to rebuild container images

2. `docker-compose up` to restart the stack with the new images

We can also combine both with `docker-compose up --build`

Compose will be smart, and only recreate the containers that have changed.

When working with interpreted languages:

- don't rebuild each time

- leverage a `volumes` section instead

---

## Launching Our First Stack with Compose

First step: clone the source code for the app we will be working on.

```bash
git clone https://github.com/jpetazzo/trainingwheels
cd trainingwheels
```

Second step: start the app.

```bash
docker-compose up
```

Watch Compose build and run the app.

That Compose stack exposes a web server on port 8000; try connecting to it.

---

## Launching Our First Stack with Compose

We should see a web page like this:

![composeapp](images/composeapp.png)

Each time we reload, the counter should increase.

---

## Stopping the app

When we hit Ctrl-C, Compose tries to gracefully terminate all of the containers.

After ten seconds (or if we press `^C` again) it will forcibly kill them.

---

## The `docker-compose.yml` file

Here is the file used in the demo:

.small[
```yaml
version: "3"

services:
  www:
    build: www
    ports:
      - ${PORT-8000}:5000
    user: nobody
    environment:
      DEBUG: 1
    command: python counter.py
    volumes:
      - ./www:/src

  redis:
    image: redis
```
]

---

## Compose file structure

A Compose file has multiple sections:

* `version` is mandatory. (Typically use "3".)

* `services` is mandatory. Each service corresponds to a container.

* `networks` is optional and indicates to which networks containers should be connected.
  <br/>(By default, containers will be connected on a private, per-compose-file network.)

* `volumes` is optional and can define volumes to be used and/or shared by the containers.

---

## Compose file versions

* Version 1 is legacy and shouldn't be used.

  (If you see a Compose file without `version` and `services`, it's a legacy v1 file.)

* Version 2 added support for networks and volumes.

* Version 3 added support for deployment options (scaling, rolling updates, etc).

* Typically use `version: "3"`.

The [Docker documentation](https://docs.docker.com/compose/compose-file/)
has excellent information about the Compose file format if you need to know more about versions.

---

## Containers in `docker-compose.yml`

Each service in the YAML file must contain either `build`, or `image`.

* `build` indicates a path containing a Dockerfile.

* `image` indicates an image name (local, or on a registry).

* If both are specified, an image will be built from the `build` directory and named `image`.

The other parameters are optional.

They encode the parameters that you would typically add to `docker run`.

Sometimes they have several minor improvements.

---

## Container parameters

* `command` indicates what to run (like `CMD` in a Dockerfile).

* `ports` translates to one (or multiple) `-p` options to map ports.
  <br/>You can specify local ports (i.e. `x:y` to expose public port `x`).

* `volumes` translates to one (or multiple) `-v` options.
  <br/>You can use relative paths here.

For the full list, check: https://docs.docker.com/compose/compose-file/

---

## Environment variables

- We can use environment variables in Compose files

  (like `$THIS` or `${THAT}`)

- We can provide default values, e.g. `${PORT-8000}`

- Compose will also automatically load the environment file `.env`

  (it should contain `VAR=value`, one per line)

- This is a great way to customize build and run parameters

  (base image versions to use, build and run secrets, port numbers...)

---

## Configuring a Compose stack

- Follow [12-factor app configuration principles][12factorconfig]

  (configure the app through environment variables)

- Provide (in the repo) a default environment file suitable for development

  (no secret or sensitive value)

- Copy the default environment file to `.env` and tweak it

  (or: provide a script to generate `.env` from a template)

[12factorconfig]: https://12factor.net/config

---

## Running multiple copies of a stack

- Copy the stack in two different directories, e.g. `front` and `frontcopy`

- Compose prefixes images and containers with the directory name:

  `front_www`, `front_www_1`, `front_db_1`

  `frontcopy_www`, `frontcopy_www_1`, `frontcopy_db_1`

- Alternatively, use `docker-compose -p frontcopy` 

  (to set the `--project-name` of a stack, which default to the dir name)

- Each copy is isolated from the others (runs on a different network)

---

## Checking stack status

We have `ps`, `docker ps`, and similarly, `docker-compose ps`:

```bash
$ docker-compose ps
Name                      Command             State           Ports          
----------------------------------------------------------------------------
trainingwheels_redis_1   /entrypoint.sh red   Up      6379/tcp               
trainingwheels_www_1     python counter.py    Up      0.0.0.0:8000->5000/tcp 
```

Shows the status of all the containers of our stack.

Doesn't show the other containers.

---

## Cleaning up (1)

If you have started your application in the background with Compose and
want to stop it easily, you can use the `kill` command:

```bash
$ docker-compose kill
```

Likewise, `docker-compose rm` will let you remove containers (after confirmation):

```bash
$ docker-compose rm
Going to remove trainingwheels_redis_1, trainingwheels_www_1
Are you sure? [yN] y
Removing trainingwheels_redis_1...
Removing trainingwheels_www_1...
```

---

## Cleaning up (2)

Alternatively, `docker-compose down` will stop and remove containers.

It will also remove other resources, like networks that were created for the application.

```bash
$ docker-compose down
Stopping trainingwheels_www_1 ... done
Stopping trainingwheels_redis_1 ... done
Removing trainingwheels_www_1 ... done
Removing trainingwheels_redis_1 ... done
```

Use `docker-compose down -v` to remove everything including volumes.

---

## Special handling of volumes

- When an image gets updated, Compose automatically creates a new container

- The data in the old container is lost...

- ...Except if the container is using a *volume*

- Compose will then re-attach that volume to the new container

  (and data is then retained across database upgrades)

- All good database images use volumes

  (e.g. all official images)

---

## Gotchas with volumes

- Unfortunately, Docker volumes don't have labels or metadata

- Compose tracks volumes thanks to their associated container

- If the container is deleted, the volume gets orphaned

- Example: `docker-compose down && docker-compose up`

  - the old volume still exists, detached from its container

  - a new volume gets created

- `docker-compose down -v`/`--volumes` deletes volumes

  (but **not** `docker-compose down && docker-compose down -v`!)
 
---

## Managing volumes explicitly

Option 1: *named volumes*

```yaml
services:
  app:
    volumes:
    - data:/some/path
volumes:
  data:
```

- Volume will be named `<project>_data`

- It won't be orphaned with `docker-compose down`

- It will correctly be removed with `docker-compose down -v`

---

## Managing volumes explicitly

Option 2: *relative paths*

```yaml
services:
  app:
    volumes:
    - ./data:/some/path
```

- Makes it easy to colocate the app and its data

  (for migration, backups, disk usage accounting...)

- Won't be removed by `docker-compose down -v`

---

## Managing complex stacks

- Compose provides multiple features to manage complex stacks

  (with many containers)

- `-f`/`--file`/`$COMPOSE_FILE` can be a list of Compose files

  (separated by `:` and merged together)

- Services can be assigned to one or more *profiles*

- `--profile`/`$COMPOSE_PROFILE` can be a list of comma-separated profiles

  (see [Using service profiles][profiles] in the Compose documentation)

- These variables can be set in `.env`

[profiles]: https://docs.docker.com/compose/profiles/

---

## Dependencies

- A service can have a `depends_on` section

  (listing one or more other services)

- This is used when bringing up individual services

  (e.g. `docker-compose up blah` or `docker-compose run foo`)

⚠️ It doesn't make a service "wait" for another one to be up!

---

class: extra-details

## A bit of history and trivia

- Compose was initially named "Fig"

- Compose is one of the only components of Docker written in Python

  (almost everything else is in Go)

- In 2020, Docker introduced "Compose CLI":

  - `docker compose` command to deploy Compose stacks to some clouds

  - progressively getting feature parity with `docker-compose`

  - also provides numerous improvements (e.g. leverages BuildKit by default)

???

:EN:- Using compose to describe an environment
:EN:- Connecting services together with a *Compose file*

:FR:- Utiliser Compose pour décrire son environnement
:FR:- Écrire un *Compose file* pour connecter les services entre eux
