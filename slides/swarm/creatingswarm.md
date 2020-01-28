# Creating our first Swarm

- The cluster is initialized with `docker swarm init`

- This should be executed on a first, seed node

- .warning[DO NOT execute `docker swarm init` on multiple nodes!]

  You would have multiple disjoint clusters.

.exercise[

- Create our cluster from node1:
  ```bash
  docker swarm init
  ```

]

--

class: advertise-addr

If Docker tells you that it `could not choose an IP address to advertise`, see next slide!

---

class: advertise-addr

## IP address to advertise

- When running in Swarm mode, each node *advertises* its address to the others
  <br/>
  (i.e. it tells them *"you can contact me on 10.1.2.3:2377"*)

- If the node has only one IP address, it is used automatically
  <br/>
  (The addresses of the loopback interface and the Docker bridge are ignored)

- If the node has multiple IP addresses, you **must** specify which one to use
  <br/>
  (Docker refuses to pick one randomly)

- You can specify an IP address or an interface name
  <br/>
  (in the latter case, Docker will read the IP address of the interface and use it)

- You can also specify a port number
  <br/>
  (otherwise, the default port 2377 will be used)

---

class: advertise-addr

## Using a non-default port number

- Changing the *advertised* port does not change the *listening* port

- If you only pass `--advertise-addr eth0:7777`, Swarm will still listen on port 2377

- You will probably need to pass `--listen-addr eth0:7777` as well

- This is to accommodate scenarios where these ports *must* be different
  <br/>
  (port mapping, load balancers...)

Example to run Swarm on a different port:

```bash
docker swarm init --advertise-addr eth0:7777 --listen-addr eth0:7777
```

---

class: advertise-addr

## Which IP address should be advertised?

- If your nodes have only one IP address, it's safe to let autodetection do the job

  .small[(Except if your instances have different private and public addresses, e.g.
  on EC2, and you are building a Swarm involving nodes inside and outside the
  private network: then you should advertise the public address.)]

- If your nodes have multiple IP addresses, pick an address which is reachable
  *by every other node* of the Swarm

- If you are using [play-with-docker](http://play-with-docker.com/), use the IP
  address shown next to the node name

  .small[(This is the address of your node on your private internal overlay network.
  The other address that you might see is the address of your node on the
  `docker_gwbridge` network, which is used for outbound traffic.)]

Examples:

```bash
docker swarm init --advertise-addr 172.24.0.2
docker swarm init --advertise-addr eth0
```

---

class: extra-details

## Using a separate interface for the data path

- You can use different interfaces (or IP addresses) for control and data

- You set the _control plane path_ with `--advertise-addr` and `--listen-addr`

  (This will be used for SwarmKit manager/worker communication, leader election, etc.)

- You set the _data plane path_ with `--data-path-addr`

  (This will be used for traffic between containers)

- Both flags can accept either an IP address, or an interface name

  (When specifying an interface name, Docker will use its first IP address)

---

## Token generation

- In the output of `docker swarm init`, we have a message
  confirming that our node is now the (single) manager:

  ```
  Swarm initialized: current node (8jud...) is now a manager.
  ```

- Docker generated two security tokens (like passphrases or passwords) for our cluster

- The CLI shows us the command to use on other nodes to add them to the cluster using the "worker"
  security token:

  ```
    To add a worker to this swarm, run the following command:
      docker swarm join \
      --token SWMTKN-1-59fl4ak4nqjmao1ofttrc4eprhrola2l87... \
      172.31.4.182:2377
  ```

---

class: extra-details

## Checking that Swarm mode is enabled

.exercise[

- Run the traditional `docker info` command:
  ```bash
  docker info
  ```

]

The output should include:

```
Swarm: active
 NodeID: 8jud7o8dax3zxbags3f8yox4b
 Is Manager: true
 ClusterID: 2vcw2oa9rjps3a24m91xhvv0c
 ...
```

---

## Running our first Swarm mode command

- Let's retry the exact same command as earlier

.exercise[

- List the nodes (well, the only node) of our cluster:
  ```bash
  docker node ls
  ```

]

The output should look like the following:
```
ID             HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
8jud...ox4b *  node1     Ready   Active        Leader
```

---

## Adding nodes to the Swarm

- A cluster with one node is not a lot of fun

- Let's add `node2`!

- We need the token that was shown earlier

--

- You wrote it down, right?

--

- Don't panic, we can easily see it again .emoji[😏]

---

## Adding nodes to the Swarm

.exercise[

- Show the token again:
  ```bash
  docker swarm join-token worker
  ```

- Log into `node2`:
  ```bash
  ssh node2
  ```

- Copy-paste the `docker swarm join ...` command
  <br/>(that was displayed just before)

<!-- ```copypaste docker swarm join --token SWMTKN.*?:2377``` -->

]

---

class: extra-details

## Check that the node was added correctly

- Stay on `node2` for now!

.exercise[

- We can still use `docker info` to verify that the node is part of the Swarm:
  ```bash
  docker info | grep ^Swarm
  ```

]

- However, Swarm commands will not work; try, for instance:
  ```bash
  docker node ls
  ```

<!-- Ignore errors: .dummy[```wait not a swarm manager```] -->

- This is because the node that we added is currently a *worker*
- Only *managers* can accept Swarm-specific commands

---

## View our two-node cluster

- Let's go back to `node1` and see what our cluster looks like

.exercise[

- Switch back to `node1` (with `exit`, `Ctrl-D` ...)

<!-- ```key ^D``` -->

- View the cluster from `node1`, which is a manager:
  ```bash
  docker node ls
  ```

]

The output should be similar to the following:
```
ID             HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
8jud...ox4b *  node1     Ready   Active        Leader
ehb0...4fvx    node2     Ready   Active
```

---

class: under-the-hood

## Under the hood: docker swarm init

When we do `docker swarm init`:

- a keypair is created for the root CA of our Swarm

- a keypair is created for the first node

- a certificate is issued for this node

- the join tokens are created

---

class: under-the-hood

## Under the hood: join tokens

There is one token to *join as a worker*, and another to *join as a manager*.

The join tokens have two parts:

- a secret key (preventing unauthorized nodes from joining)

- a fingerprint of the root CA certificate (preventing MITM attacks)

If a token is compromised, it can be rotated instantly with:
```
docker swarm join-token --rotate <worker|manager>
```

---

class: under-the-hood

## Under the hood: docker swarm join

When a node joins the Swarm:

- it is issued its own keypair, signed by the root CA

- if the node is a manager:

  - it joins the Raft consensus
  - it connects to the current leader
  - it accepts connections from worker nodes

- if the node is a worker:

  - it connects to one of the managers (leader or follower)

---

class: under-the-hood

## Under the hood: cluster communication

- The *control plane* is encrypted with AES-GCM; keys are rotated every 12 hours

- Authentication is done with mutual TLS; certificates are rotated every 90 days

  (`docker swarm update` allows to change this delay or to use an external CA)

- The *data plane* (communication between containers) is not encrypted by default

  (but this can be activated on a by-network basis, using IPSEC,
  leveraging hardware crypto if available)

---

class: under-the-hood

## Under the hood: I want to know more!

Revisit SwarmKit concepts:

- Docker 1.12 Swarm Mode Deep Dive Part 1: Topology
  ([video](https://www.youtube.com/watch?v=dooPhkXT9yI))

- Docker 1.12 Swarm Mode Deep Dive Part 2: Orchestration
  ([video](https://www.youtube.com/watch?v=_F6PSP-qhdA))

Some presentations from the Docker Distributed Systems Summit in Berlin:

- Heart of the SwarmKit: Topology Management
  ([slides](https://speakerdeck.com/aluzzardi/heart-of-the-swarmkit-topology-management))

- Heart of the SwarmKit: Store, Topology & Object Model
  ([slides](https://www.slideshare.net/Docker/heart-of-the-swarmkit-store-topology-object-model))
  ([video](https://www.youtube.com/watch?v=EmePhjGnCXY))

And DockerCon Black Belt talks:

.blackbelt[DC17US: Everything You Thought You Already Knew About Orchestration
 ([video](https://www.youtube.com/watch?v=Qsv-q8WbIZY&list=PLkA60AVN3hh-biQ6SCtBJ-WVTyBmmYho8&index=6))]

.blackbelt[DC17EU: Container Orchestration from Theory to Practice
 ([video](https://dockercon.docker.com/watch/5fhwnQxW8on1TKxPwwXZ5r))]

