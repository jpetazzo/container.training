# Dealing with stateful services

- First of all, you need to make sure that the data files are on a *volume*

- Volumes are host directories that are mounted to the container's filesystem

- These host directories can be backed by the ordinary, plain host filesystem ...

- ... Or by distributed/networked filesystems

- In the latter scenario, in case of node failure, the data is safe elsewhere ...

- ... And the container can be restarted on another node without data loss

---

## Building a stateful service experiment

- We will use Redis for this example

- We will expose it on port 10000 to access it easily

.lab[

- Start the Redis service:
  ```bash
  docker service create --name stateful -p 10000:6379 redis
  ```

- Check that we can connect to it:
  ```bash
  docker run --net host --rm redis redis-cli -p 10000 info server
  ```

]

---

## Accessing our Redis service easily

- Typing that whole command is going to be tedious

.lab[

- Define a shell alias to make our lives easier:
  ```bash
  alias redis='docker run --net host --rm redis redis-cli -p 10000'
  ```

- Try it:
  ```bash
  redis info server
  ```

]

---

## Basic Redis commands

.lab[

- Check that the `foo` key doesn't exist:
  ```bash
  redis get foo
  ```

- Set it to `bar`:
  ```bash
  redis set foo bar
  ```

- Check that it exists now:
  ```bash
  redis get foo
  ```

]

---

## Local volumes vs. global volumes

- Global volumes exist in a single namespace

- A global volume can be mounted on any node
  <br/>.small[(bar some restrictions specific to the volume driver in use; e.g. using an EBS-backed volume on a GCE/EC2 mixed cluster)]

- Attaching a global volume to a container allows to start the container anywhere
  <br/>(and retain its data wherever you start it!)

- Global volumes require extra *plugins* (Flocker, Portworx...)

- Docker doesn't come with a default global volume driver at this point

- Therefore, we will fall back on *local volumes*

---

## Local volumes

- We will use the default volume driver, `local`

- As the name implies, the `local` volume driver manages *local* volumes

- Since local volumes are (duh!) *local*, we need to pin our container to a specific host

- We will do that with a *constraint*

.lab[

- Add a placement constraint to our service:
  ```bash
  docker service update stateful --constraint-add node.hostname==$HOSTNAME
  ```

]

---

## Where is our data?

- If we look for our `foo` key, it's gone!

.lab[

- Check the `foo` key:
  ```bash
  redis get foo
  ```

- Adding a constraint caused the service to be redeployed:
  ```bash
  docker service ps stateful
  ```

]

Note: even if the constraint ends up being a no-op (i.e. not
moving the service), the service gets redeployed.
This ensures consistent behavior.

---

## Setting the key again

- Since our database was wiped out, let's populate it again

.lab[

- Set `foo` again:
  ```bash
  redis set foo bar
  ```

- Check that it's there:
  ```bash
  redis get foo
  ```

]

---

## Updating a service recreates its containers

- Let's try to make a trivial update to the service and see what happens

.lab[

- Set a memory limit to our Redis service:
  ```bash
  docker service update stateful --limit-memory 100M
  ```

- Try to get the `foo` key one more time:
  ```bash
  redis get foo
  ```

]

The key is blank again!

---

## Service volumes are ephemeral by default

- Let's highlight what's going on with volumes!

.lab[

- Check the current list of volumes:
  ```bash
  docker volume ls
  ```

- Carry a minor update to our Redis service:
  ```bash
  docker service update stateful --limit-memory 200M
  ```

]

Again: all changes trigger the creation of a new task, and therefore a replacement of the existing container;
even when it is not strictly technically necessary.

---

## The data is gone again

- What happened to our data?

.lab[

- The list of volumes is slightly different:
  ```bash
  docker volume ls
  ```

]

(You should see one extra volume.)

---

## Assigning a persistent volume to the container

- Let's add an explicit volume mount to our service, referencing a named volume

.lab[

- Update the service with a volume mount:
  ```bash
    docker service update stateful \
           --mount-add type=volume,source=foobarstore,target=/data
  ```

- Check the new volume list:
  ```bash
  docker volume ls
  ```

]

Note: the `local` volume driver automatically creates volumes.

---

## Checking that data is now persisted correctly

.lab[

- Store something in the `foo` key:
  ```bash
  redis set foo barbar
  ```

- Update the service with yet another trivial change:
  ```bash
  docker service update stateful --limit-memory 300M
  ```

- Check that `foo` is still set:
  ```bash
  redis get foo
  ```

]

---

## Recap

- The service must commit its state to disk when being shutdown.red[*]

  (Shutdown = being sent a `TERM` signal)

- The state must be written on files located on a volume

- That volume must be specified to be persistent

- If using a local volume, the service must also be pinned to a specific node

  (And losing that node means losing the data, unless there are other backups)

.footnote[<br/>
.red[*]If you customize Redis configuration, make sure you
persist data correctly!
<br/>
It's easy to make that mistake — __Trust me!__]

---

## Cleaning up

.lab[

- Remove the stateful service:
  ```bash
  docker service rm stateful
  ```

- Remove the associated volume:
  ```bash
  docker volume rm foobarstore
  ```

]

Note: we could keep the volume around if we wanted.

---

## Should I run stateful services in containers?

--

Depending whom you ask, they'll tell you:

--

- certainly not, heathen!

--

- we've been running a few thousands PostgreSQL instances in containers ...
  <br/>for a few years now ... in production ... is that bad?

--

- what's a container?

--

Perhaps a better question would be:

*"Should I run stateful services?"*

--

- is it critical for my business?
- is it my value-add?
- or should I find somebody else to run them for me?
