## Adding nodes using the Docker API

- We don't have to SSH into the other nodes, we can use the Docker API

- If you are using Play-With-Docker:

  - the nodes expose the Docker API over port 2375/tcp, without authentication

  - we will connect by setting the `DOCKER_HOST` environment variable

- Otherwise:

  - the nodes expose the Docker API over port 2376/tcp, with TLS mutual authentication

  - we will use Docker Machine to set the correct environment variables
    <br/>(the nodes have been suitably pre-configured to be controlled through `node1`)

---

# Docker Machine

- Docker Machine has two primary uses:

  - provisioning cloud instances running the Docker Engine

  - managing local Docker VMs within e.g. VirtualBox

- Docker Machine is purely optional

- It makes it easy to create, upgrade, manage... Docker hosts:

  - on your favorite cloud provider

  - locally (e.g. to test clustering, or different versions)

  - across different cloud providers

---

class: self-paced

## If you're using Play-With-Docker ...

- You won't need to use Docker Machine

- Instead, to "talk" to another node, we'll just set `DOCKER_HOST`

- You can skip the commands telling you to do things with Docker Machine!

---

## Docker Machine basic usage

- We will learn two commands:

  - `docker-machine ls` (list existing hosts)

  - `docker-machine env` (switch to a specific host)

.lab[

- List configured hosts:
  ```bash
  docker-machine ls
  ```

]

You should see your 5 nodes.

---

class: in-person

## How did we make our 5 nodes show up there?

*For the curious...*

- This was done by our VM provisioning scripts

- After setting up everything else, `node1` adds the 5 nodes
  to the local Docker Machine configuration
  (located in `$HOME/.docker/machine`)

- Nodes are added using [Docker Machine generic driver](https://docs.docker.com/machine/drivers/generic/)

  (It skips machine provisioning and jumps straight to the configuration phase)

- Docker Machine creates TLS certificates and deploys them to the nodes through SSH

---

## Selecting a node with Docker Machine

- To select a node, use `eval $(docker-machine env nodeX)`

- This sets a number of environment variables

- To unset these variables, use `eval $(docker-machine env -u)`

.lab[

- View the variables used by Docker Machine:
  ```bash
  docker-machine env node3
  ```

]

(This shows which variables *would* be set by Docker Machine; but it doesn't change them.)

---

## Getting the token

- First, let's store the join token in a variable

- This must be done from a manager

.lab[

- Make sure we talk to the local node, or `node1`:
  ```bash
  eval $(docker-machine env -u)
  ```

- Get the join token:
  ```bash
  TOKEN=$(docker swarm join-token -q worker)
  ```

]

---

## Change the node targeted by the Docker CLI

- We need to set the right environment variables to communicate with `node3`

.lab[

- If you're using Play-With-Docker:
  ```bash
  export DOCKER_HOST=tcp://node3:2375
  ```

- Otherwise, use Docker Machine:
  ```bash
  eval $(docker-machine env node3)
  ```

]

---

## Checking which node we're talking to

- Let's use the Docker API to ask "who are you?" to the remote node

.lab[

- Extract the node name from the output of `docker info`:
  ```bash
  docker info | grep ^Name
  ```

]

This should tell us that we are talking to `node3`.

Note: it can be useful to use a [custom shell prompt](
https://@@GITREPO@@/blob/master/prepare-vms/scripts/postprep.rc#L68)
reflecting the `DOCKER_HOST` variable.

---

## Adding a node through the Docker API

- We are going to use the same `docker swarm join` command as before

.lab[

- Add `node3` to the Swarm:
  ```bash
  docker swarm join --token $TOKEN node1:2377
  ```

]

---

## Going back to the local node

- We need to revert the environment variable(s) that we had set previously

.lab[

- If you're using Play-With-Docker, just clear `DOCKER_HOST`:
  ```bash
  unset DOCKER_HOST
  ```

- Otherwise, use Docker Machine to reset all the relevant variables:
  ```bash
  eval $(docker-machine env -u)
  ```

]

From that point, we are communicating with `node1` again.

---

## Checking the composition of our cluster

- Now that we're talking to `node1` again, we can use management commands

.lab[

- Check that the node is here:
  ```bash
  docker node ls
  ```

]
