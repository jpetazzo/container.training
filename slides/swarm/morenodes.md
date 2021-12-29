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
for N in $(seq 3 5); do
  export DOCKER_HOST=tcp://node$N:2375
  docker swarm join --token $TOKEN node1:2377
done
unset DOCKER_HOST
```

---

class: in-person

## Building our full cluster

- Let's get the token, and use a one-liner for the remaining node with SSH

.lab[

- Obtain the manager token:
  ```bash
  TOKEN=$(docker swarm join-token -q manager)
  ```

- Add the remaining node:
  ```bash
    ssh node3 docker swarm join --token $TOKEN node1:2377
  ```

]

[That was easy.](https://www.youtube.com/watch?v=3YmMNpbFjp0)

---

## Controlling the Swarm from other nodes

.lab[

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

.lab[

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

- 7 managers and more = now you might be overdoing it for most designs

.footnote[

 see [Docker's admin guide](https://docs.docker.com/engine/swarm/admin_guide/#add-manager-nodes-for-fault-tolerance) 
 on node failure and datacenter redundancy

]

---

## Why not have *all* nodes be managers?

- With Raft, writes have to go to (and be acknowledged by) all nodes

- Thus, it's harder to reach consensus in larger groups

- Only one manager is Leader (writable), so more managers ≠ more capacity

- Managers should be &#60; 10ms latency from each other

- These design parameters lead us to recommended designs

---

## What would McGyver do?

- Keep managers in one region (multi-zone/datacenter/rack)

- Groups of 3 or 5 nodes: all are managers. Beyond 5, separate out managers and workers

- Groups of 10-100 nodes: pick 5 "stable" nodes to be managers

- Groups of more than 100 nodes: watch your managers' CPU and RAM

  - 16GB memory or more, 4 CPU's or more, SSD's for Raft I/O
  - otherwise, break down your nodes in multiple smaller clusters

.footnote[

  Cloud pro-tip: use separate auto-scaling groups for managers and workers

  See docker's "[Running Docker at scale](https://success.docker.com/article/running-docker-ee-at-scale)" document
]
---

## What's the upper limit?

- We don't know!

- Internal testing at Docker Inc.: 1000-10000 nodes is fine

  - deployed to a single cloud region

  - one of the main take-aways was *"you're gonna need a bigger manager"*

- Testing by the community: [4700 heterogeneous nodes all over the 'net](https://sematext.com/blog/2016/11/14/docker-swarm-lessons-from-swarm3k/)

  - it just works, assuming they have the resources

  - more nodes require manager CPU and networking; more containers require RAM

  - scheduling of large jobs (70,000 containers) is slow, though ([getting better](https://github.com/moby/moby/pull/37372)!)

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
