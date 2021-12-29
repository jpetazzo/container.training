class: namespaces
name: namespaces

# Improving isolation with User Namespaces

- *Namespaces* are kernel mechanisms to compartmentalize the system

- There are different kind of namespaces: `pid`, `net`, `mnt`, `ipc`, `uts`, and `user`

- For a primer, see "Anatomy of a Container"
  ([video](https://www.youtube.com/watch?v=sK5i-N34im8))
  ([slides](https://www.slideshare.net/jpetazzo/cgroups-namespaces-and-beyond-what-are-containers-made-from-dockercon-europe-2015))

- The *user namespace* allows to map UIDs between the containers and the host

- As a result, `root` in a container can map to a non-privileged user on the host

Note: even without user namespaces, `root` in a container cannot go wild on the host.
<br/>
It is mediated by capabilities, cgroups, namespaces, seccomp, LSMs...

---

class: namespaces

## User Namespaces in Docker

- Optional feature added in Docker Engine 1.10

- Not enabled by default

- Has to be enabled at Engine startup, and affects all containers

- When enabled, `UID:GID` in containers are mapped to a different range on the host

- Safer than switching to a non-root user (with `-u` or `USER`) in the container
  <br/>
  (Since with user namespaces, root escalation maps to a non-privileged user)

- Can be selectively disabled per container by starting them with `--userns=host`

---

class: namespaces

## User Namespaces Caveats

When user namespaces are enabled, containers cannot:

- Use the host's network namespace (with `docker run --network=host`)

- Use the host's PID namespace (with `docker run --pid=host`)

- Run in privileged mode (with `docker run --privileged`)

... Unless user namespaces are disabled for the container, with flag `--userns=host`

External volume and graph drivers that don't support user mapping might not work.

All containers are currently mapped to the same UID:GID range.

Some of these limitations might be lifted in the future!

---

class: namespaces

## Filesystem ownership details

When enabling user namespaces:

- the UID:GID on disk (in the images and containers) has to match the *mapped* UID:GID

- existing images and containers cannot work (their UID:GID would have to be changed)

For practical reasons, when enabling user namespaces, the Docker Engine places containers and images (and everything else) in a different directory.

As a result, if you enable user namespaces on an existing installation:

-  all containers and images (and e.g. Swarm data) disappear

- *if a node is a member of a Swarm, it is then kicked out of the Swarm*

-  everything will re-appear if you disable user namespaces again

---

class: namespaces

## Picking a node

- We will select a node where we will enable user namespaces

- This node will have to be re-added to the Swarm

- All containers and services running on this node will be rescheduled

- Let's make sure that we do not pick the node running the registry!

.lab[

- Check on which node the registry is running:
  ```bash
  docker service ps registry
  ```

]

Pick any other node (noted `nodeX` in the next slides).

---

class: namespaces

## Logging into the right Engine

.lab[

- Log into the right node:
  ```bash
  ssh node`X`
  ```

]

---

class: namespaces

## Configuring the Engine

.lab[

- Create a configuration file for the Engine:
  ```bash
  echo '{"userns-remap": "default"}' | sudo tee /etc/docker/daemon.json
  ```

- Restart the Engine:
  ```bash
  kill $(pidof dockerd)
  ```

]

---

class: namespaces 

## Checking that User Namespaces are enabled

.lab[
  - Notice the new Docker path:
  ```bash
  docker info | grep var/lib
  ```

  - Notice the new UID:GID permissions:
  ```bash
  sudo ls -l /var/lib/docker
  ```

]

You should see a line like the following:
```
drwx------ 11 296608 296608 4096 Aug  3 05:11 296608.296608
```

---

class: namespaces

## Add the node back to the Swarm

.lab[

- Get our manager token from another node:
  ```bash
  ssh node`Y` docker swarm join-token manager
  ```

- Copy-paste the join command to the node

]

---

class: namespaces

## Check the new UID:GID

.lab[

- Run a background container on the node:
  ```bash
  docker run -d --name lockdown alpine sleep 1000000
  ```

- Look at the processes in this container:
  ```bash
  docker top lockdown
  ps faux
  ```

]

---

class: namespaces

## Comparing on-disk ownership with/without User Namespaces

.lab[

- Compare the output of the two following commands:
  ```bash
  docker run alpine ls -l /
  docker run --userns=host alpine ls -l /
  ```

]

--

class: namespaces

In the first case, it looks like things belong to `root:root`.

In the second case, we will see the "real" (on-disk) ownership.

--

class: namespaces

Remember to get back to `node1` when finished!
