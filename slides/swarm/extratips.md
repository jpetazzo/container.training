# Controlling Docker from a container

- In a local environment, just bind-mount the Docker control socket:
  ```bash
  docker run -ti -v /var/run/docker.sock:/var/run/docker.sock docker
  ```

- Otherwise, you have to:

  - set `DOCKER_HOST`,
  - set `DOCKER_TLS_VERIFY` and `DOCKER_CERT_PATH` (if you use TLS),
  - copy certificates to the container that will need API access.

More resources on this topic:

- [Do not use Docker-in-Docker for CI](
  https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)
- [One container to rule them all](
  https://jpetazzo.github.io/2016/04/03/one-container-to-rule-them-all/)

---

## Bind-mounting the Docker control socket

- In Swarm mode, bind-mounting the control socket gives you access to the whole cluster

- You can tell Docker to place a given service on a manager node, using constraints:
  ```bash
    docker service create \
      --mount source=/var/run/docker.sock,type=bind,target=/var/run/docker.sock \
      --name autoscaler --constraint node.role==manager ...
  ```

---

## Constraints and global services

(New in Docker Engine 1.13)

- By default, global services run on *all* nodes
  ```bash
  docker service create --mode global ...
  ```

- You can specify constraints for global services

- These services will run only on the node satisfying the constraints

- For instance, this service will run on all manager nodes:
  ```bash
  docker service create --mode global --constraint node.role==manager ...
  ```

---

## Constraints and dynamic scheduling

(New in Docker Engine 1.13)

- If constraints change, services are started/stopped accordingly

  (e.g., `--constraint node.role==manager` and nodes are promoted/demoted)

- This is particularly useful with labels:
  ```bash
  docker node update node1 --label-add defcon=five
  docker service create --constraint node.labels.defcon==five ...
  docker node update node2 --label-add defcon=five
  docker node update node1 --label-rm defcon=five
  ```

---

## Shortcomings of dynamic scheduling

.warning[If a service becomes "unschedulable" (constraints can't be satisfied):]

- It won't be scheduled automatically when constraints are satisfiable again

- You will have to update the service; you can do a no-op update with:
  ```bash
  docker service update ... --force
  ```

.warning[Docker will silently ignore attempts to remove a non-existent label or constraint]

- It won't warn you if you typo when removing a label or constraint!

---

# Node management

- SwarmKit allows to change (almost?) everything on-the-fly

- Nothing should require a global restart

---

## Node availability

```bash
docker node update <node-name> --availability <active|pause|drain>
```

- Active = schedule tasks on this node (default)

- Pause = don't schedule new tasks on this node; existing tasks are not affected

  You can use it to troubleshoot a node without disrupting existing tasks

  It can also be used (in conjunction with labels) to reserve resources

- Drain = don't schedule new tasks on this node; existing tasks are moved away

  This is just like crashing the node, but containers get a chance to shutdown cleanly

---

## Managers and workers

- Nodes can be promoted to manager with `docker node promote`

- Nodes can be demoted to worker with `docker node demote`

- This can also be done with `docker node update <node> --role <manager|worker>`

- Reminder: this has to be done from a manager node
  <br/>(workers cannot promote themselves)

---

## Removing nodes

- You can leave Swarm mode with `docker swarm leave`

- Nodes are drained before being removed (i.e. all tasks are rescheduled somewhere else)

- Managers cannot leave (they have to be demoted first)

- After leaving, a node still shows up in `docker node ls` (in `Down` state)

- When a node is `Down`, you can remove it with `docker node rm` (from a manager node)

---

## Join tokens and automation

- If you have used Docker 1.12-RC: join tokens are now mandatory!

- You cannot specify your own token (SwarmKit generates it)

- If you need to change the token: `docker swarm join-token --rotate ...`

- To automate cluster deployment:

  - have a seed node do `docker swarm init` if it's not already in Swarm mode

  - propagate the token to the other nodes (secure bucket, facter, ohai...)

---

## Viewing disk usage: `docker system df`

(New in Docker Engine 1.13)

- Shows disk usage for images, containers, and volumes

- Breaks down between *active* and *reclaimable* categories

.lab[

- Check how much disk space is used at the end of the workshop:
  ```bash
  docker system df
  ```

]

---

## Cleaning up disk: `docker system prune`

- Removes stopped containers

- Removes dangling images (that don't have a tag associated anymore)

- Removes orphaned volumes

- Removes empty networks

.lab[

- Try it:
  ```bash
  docker system prune -f
  ```

]

Note: `docker system prune -a` will also remove *unused* images.

---

## Events

- You can get a real-time stream of events with `docker events`

- This will report *local events* and *cluster events*

- Local events =
  <br/>
  all activity related to containers, images, plugins, volumes, networks, *on this node*

- Cluster events =
  <br/>Swarm Mode activity related to services, nodes, secrets, configs, *on the whole cluster*

- `docker events` doesn't report *local events happening on other nodes*

- Events can be filtered (by type, target, labels...)

- Events can be formatted with Go's `text/template` or in JSON

---

## Getting *all the events*

- There is no built-in to get a stream of *all the events* on *all the nodes*

- This can be achieved with (for instance) the four following services working together:

  - a Redis container (used as a stateless, fan-in message queue)

  - a global service bind-mounting the Docker socket, pushing local events to the queue

  - a similar singleton service to push global events to the queue

  - a queue consumer fetching events and processing them as you please

I'm not saying that you should implement it with Shell scripts, but you totally could.

.small[
(It might or might not be one of the initiating rites of the
[House of Bash](https://twitter.com/carmatrocity/status/676559402787282944))
]

For more information about event filters and types, check [the documentation](https://docs.docker.com/engine/reference/commandline/events/).
