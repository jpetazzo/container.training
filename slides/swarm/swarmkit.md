# SwarmKit

- [SwarmKit](https://github.com/docker/swarmkit) is an open source
  toolkit to build multi-node systems

- It is a reusable library, like libcontainer, libnetwork, vpnkit ...

- It is a plumbing part of the Docker ecosystem

--

.footnote[🐳 Did you know that кит means "whale" in Russian?]

---

## SwarmKit features

- Highly-available, distributed store based on [Raft](
  https://en.wikipedia.org/wiki/Raft_%28computer_science%29)
  <br/>(avoids depending on an external store: easier to deploy; higher performance)

- Dynamic reconfiguration of Raft without interrupting cluster operations

- *Services* managed with a *declarative API*
  <br/>(implementing *desired state* and *reconciliation loop*)

- Integration with overlay networks and load balancing

- Strong emphasis on security:

  - automatic TLS keying and signing; automatic cert rotation
  - full encryption of the data plane; automatic key rotation
  - least privilege architecture (single-node compromise ≠ cluster compromise)
  - on-disk encryption with optional passphrase

---

class: extra-details

## Where is the key/value store?

- Many orchestration systems use a key/value store backed by a consensus algorithm
  <br/>
  (k8s→etcd→Raft, mesos→zookeeper→ZAB, etc.)

- SwarmKit implements the Raft algorithm directly
  <br/>
  (Nomad is similar; thanks [@cbednarski](https://twitter.com/@cbednarski),
  [@diptanu](https://twitter.com/diptanu) and others for pointing it out!)

- Analogy courtesy of [@aluzzardi](https://twitter.com/aluzzardi):

  *It's like B-Trees and RDBMS. They are different layers, often
  associated. But you don't need to bring up a full SQL server when
  all you need is to index some data.*

- As a result, the orchestrator has direct access to the data
  <br/>
  (the main copy of the data is stored in the orchestrator's memory)

- Simpler, easier to deploy and operate; also faster

---

## SwarmKit concepts (1/2)

- A *cluster* will be at least one *node* (preferably more)

- A *node* can be a *manager* or a *worker*

- A *manager* actively takes part in the Raft consensus, and keeps the Raft log

- You can talk to a *manager* using the SwarmKit API

- One *manager* is elected as the *leader*; other managers merely forward requests to it

- The *workers* get their instructions from the *managers*

- Both *workers* and *managers* can run containers

---

## Illustration

On the next slide:

- whales = nodes (workers and managers)

- monkeys = managers

- purple monkey = leader

- grey monkeys = followers

- dotted triangle = raft protocol

---

class: pic

![Illustration](images/swarm-mode.svg)

---

## SwarmKit concepts (2/2)

- The *managers* expose the SwarmKit API

- Using the API, you can indicate that you want to run a *service*

- A *service* is specified by its *desired state*: which image, how many instances...

- The *leader* uses different subsystems to break down services into *tasks*:
  <br/>orchestrator, scheduler, allocator, dispatcher

- A *task* corresponds to a specific container, assigned to a specific *node*

- *Nodes* know which *tasks* should be running, and will start or stop containers accordingly (through the Docker Engine API)

You can refer to the [NOMENCLATURE](https://github.com/docker/swarmkit/blob/master/design/nomenclature.md) in the SwarmKit repo for more details.
