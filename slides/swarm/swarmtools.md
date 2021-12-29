# SwarmKit debugging tools

- The SwarmKit repository comes with debugging tools

- They are *low level* tools; not for general use

- We are going to see two of these tools:

  - `swarmctl`, to communicate directly with the SwarmKit API

  - `swarm-rafttool`, to inspect the content of the Raft log

---

## Building the SwarmKit tools

- We are going to install a Go compiler, then download SwarmKit source and build it

.lab[
- Download, compile, and install SwarmKit with this one-liner:
  ```bash
  docker run -v /usr/local/bin:/go/bin golang \
         go get `-v` github.com/docker/swarmkit/...
  ```

]

Remove `-v` if you don't like verbose things.

Shameless promo: for more Go and Docker love, check
[this blog post](https://jpetazzo.github.io/2016/09/09/go-docker/)!

Note: in the unfortunate event of SwarmKit *master* branch being broken,
the build might fail. In that case, just skip the Swarm tools section.

---

## Getting cluster-wide task information

- The Docker API doesn't expose this directly (yet)

- But the SwarmKit API does

- We are going to query it with `swarmctl`

- `swarmctl` is an example program showing how to
  interact with the SwarmKit API

---

## Using `swarmctl`

- The Docker Engine places the SwarmKit control socket in a special path

- You need root privileges to access it

.lab[

- If you are using Play-With-Docker, set the following alias:
  ```bash
    alias swarmctl='/lib/ld-musl-x86_64.so.1 /usr/local/bin/swarmctl \
                    --socket /var/run/docker/swarm/control.sock'
  ```

- Otherwise, set the following alias:
  ```bash
    alias swarmctl='sudo swarmctl \
                    --socket /var/run/docker/swarm/control.sock'
  ```

]

---

## `swarmctl` in action

- Let's review a few useful `swarmctl` commands

.lab[

- List cluster nodes (that's equivalent to `docker node ls`):
  ```bash
  swarmctl node ls
  ```

- View all tasks across all services:
  ```bash
  swarmctl task ls
  ```

]

---

## `swarmctl` notes

- SwarmKit is vendored into the Docker Engine

- If you want to use `swarmctl`, you need the exact version of
  SwarmKit that was used in your Docker Engine

- Otherwise, you might get some errors like:

  ```
  Error: grpc: failed to unmarshal the received message proto: wrong wireType = 0
  ```

- With Docker 1.12, the control socket was in `/var/lib/docker/swarm/control.sock`

---

## `swarm-rafttool`

- SwarmKit stores all its important data in a distributed log using the Raft protocol

  (This log is also simply called the "Raft log")

- You can decode that log with `swarm-rafttool`

- This is a great tool to understand how SwarmKit works

- It can also be used in forensics or troubleshooting

  (But consider it as a *very low level* tool!)

---

## The powers of `swarm-rafttool`

With `swarm-rafttool`, you can:

- view the latest snapshot of the cluster state;

- view the Raft log (i.e. changes to the cluster state);

- view specific objects from the log or snapshot;

- decrypt the Raft data (to analyze it with other tools).

It *cannot* work on live files, so you must stop Docker or make a copy first.

---

## Using `swarm-rafttool`

- First, let's make a copy of the current Swarm data

.lab[

- If you are using Play-With-Docker, the Docker data directory is `/graph`:
  ```bash
  cp -r /graph/swarm /swarmdata
  ```

<!-- ```wait cp: cannot stat``` -->

- Otherwise, it is in the default `/var/lib/docker`:
  ```bash
  sudo cp -r /var/lib/docker/swarm /swarmdata
  ```

]

---

## Dumping the Raft log

- We have to indicate the path holding the Swarm data

  (Otherwise `swarm-rafttool` will try to use the live data, and complain that it's locked!)

.lab[

- If you are using Play-With-Docker, you must use the musl linker:
  ```bash
  /lib/ld-musl-x86_64.so.1 /usr/local/bin/swarm-rafttool -d /swarmdata/ dump-wal
  ```

<!-- ```wait -bash:``` -->

- Otherwise, you don't need the musl linker but you need to get root:
  ```bash
  sudo swarm-rafttool -d /swarmdata/ dump-wal
  ```

]

Reminder: this is a very low-level tool, requiring a knowledge of SwarmKit's internals!
