## Adding more manager nodes

- Right now, we have only one manager (node1)

- If we lose it, we lose quorum - and that's *very bad!*

- Containers running on other nodes will be fine ...

- But we won't be able to get or set anything related to the cluster

- If the manager is permanently gone, we will have to do a manual repair!

- Nobody wants to do that ... so let's make our cluster highly available

---

class: self-paced

## Adding more managers

With Play-With-Docker:

```bash
TOKEN=$(docker swarm join-token -q manager)
for N in $(seq 4 5); do
  export DOCKER_HOST=tcp://node$N:2375
  docker swarm join --token $TOKEN node1:2377
done
unset DOCKER_HOST
```

---

class: in-person

## Building our full cluster

- We could SSH to nodes 3, 4, 5; and copy-paste the command

--

class: in-person

- Or we could use the AWESOME POWER OF THE SHELL!

--

class: in-person

![Mario Red Shell](images/mario-red-shell.png)

--

class: in-person

- No, not *that* shell

---

class: in-person

## Let's form like Swarm-tron

- Let's get the token, and loop over the remaining nodes with SSH

.exercise[

- Obtain the manager token:
  ```bash
  TOKEN=$(docker swarm join-token -q manager)
  ```

- Loop over the 3 remaining nodes:
  ```bash
    for NODE in node3 node4 node5; do
      ssh $NODE docker swarm join --token $TOKEN node1:2377
    done
  ```

]

[That was easy.](https://www.youtube.com/watch?v=3YmMNpbFjp0)

---

## Controlling the Swarm from other nodes

.exercise[

- Try the following command on a few different nodes:
  ```bash
  docker node ls
  ```

]

On manager nodes:
<br/>you will see the list of nodes, with a `*` denoting
the node you're talking to.

On non-manager nodes:
<br/>you will get an error message telling you that
the node is not a manager.

As we saw earlier, you can only control the Swarm through a manager node.

---

class: self-paced

## Play-With-Docker node status icon

- If you're using Play-With-Docker, you get node status icons

- Node status icons are displayed left of the node name

  - No icon = no Swarm mode detected
  - Solid blue icon = Swarm manager detected
  - Blue outline icon = Swarm worker detected

![Play-With-Docker icons](images/pwd-icons.png)

---

## Dynamically changing the role of a node

- We can change the role of a node on the fly:

  `docker node promote nodeX` → make nodeX a manager
  <br/>
  `docker node demote nodeX` → make nodeX a worker

.exercise[

- See the current list of nodes:
  ```
  docker node ls
  ```

- Promote any worker node to be a manager:
  ```
  docker node promote <node_name_or_id>
  ```

]

---

## How many managers do we need?

- 2N+1 nodes can (and will) tolerate N failures
  <br/>(you can have an even number of managers, but there is no point)

--

- 1 manager = no failure

- 3 managers = 1 failure

- 5 managers = 2 failures (or 1 failure during 1 maintenance)

- 7 managers and more = now you might be overdoing it a little bit

---

## Why not have *all* nodes be managers?

- Intuitively, it's harder to reach consensus in larger groups

- With Raft, writes have to go to (and be acknowledged by) all nodes

- More nodes = more network traffic

- Bigger network = more latency

---

## What would McGyver do?

- If some of your machines are more than 10ms away from each other,
  <br/>
  try to break them down in multiple clusters
  (keeping internal latency low)

- Groups of up to 9 nodes: all of them are managers

- Groups of 10 nodes and up: pick 5 "stable" nodes to be managers
  <br/>
  (Cloud pro-tip: use separate auto-scaling groups for managers and workers)

- Groups of more than 100 nodes: watch your managers' CPU and RAM

- Groups of more than 1000 nodes:

  - if you can afford to have fast, stable managers, add more of them
  - otherwise, break down your nodes in multiple clusters

---

## What's the upper limit?

- We don't know!

- Internal testing at Docker Inc.: 1000-10000 nodes is fine

  - deployed to a single cloud region

  - one of the main take-aways was *"you're gonna need a bigger manager"*

- Testing by the community: [4700 heterogenous nodes all over the 'net](https://sematext.com/blog/2016/11/14/docker-swarm-lessons-from-swarm3k/)

  - it just works

  - more nodes require more CPU; more containers require more RAM

  - scheduling of large jobs (70000 containers) is slow, though (working on it!)

---

## Real-life deployment methods

--

Running commands manually over SSH

--

  (lol jk)

--

- Using your favorite configuration management tool

- [Docker for AWS](https://docs.docker.com/docker-for-aws/#quickstart)

- [Docker for Azure](https://docs.docker.com/docker-for-azure/)
