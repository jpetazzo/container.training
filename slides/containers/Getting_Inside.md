
class: title

# Getting inside a container

![Person standing inside a container](images/getting-inside.png)

---

## Objectives

On a traditional server or VM, we sometimes need to:

* log into the machine (with SSH or on the console),

* analyze the disks (by removing them or rebooting with a rescue system).

In this chapter, we will see how to do that with containers.

---

## Getting a shell

Every once in a while, we want to log into a machine.

In an perfect world, this shouldn't be necessary.

* You need to install or update packages (and their configuration)?

  Use configuration management. (e.g. Ansible, Chef, Puppet, Salt...)

* You need to view logs and metrics?

  Collect and access them through a centralized platform.

In the real world, though ... we often need shell access!

---

## Not getting a shell

Even without a perfect deployment system, we can do many operations without getting a shell.

* Installing packages can (and should) be done in the container image.

* Configuration can be done at the image level, or when the container starts.

* Dynamic configuration can be stored in a volume (shared with another container).

* Logs written to stdout are automatically collected by the Docker Engine.

* Other logs can be written to a shared volume.

* Process information and metrics are visible from the host.

_Let's save logging, volumes ... for later, but let's have a look at process information!_

---

## Viewing container processes from the host

If you run Docker on Linux, container processes are visible on the host.

```bash
$ ps faux | less
```

* Scroll around the output of this command.

* You should see the `jpetazzo/clock` container.

* A containerized process is just like any other process on the host.

* We can use tools like `lsof`, `strace`, `gdb` ... To analyze them.

---

class: extra-details

## What's the difference between a container process and a host process?

* Each process (containerized or not) belongs to *namespaces* and *cgroups*.

* The namespaces and cgroups determine what a process can "see" and "do".

* Analogy: each process (containerized or not) runs with a specific UID (user ID).

* UID=0 is root, and has elevated privileges. Other UIDs are normal users.

_We will give more details about namespaces and cgroups later._

---

## Getting a shell in a running container

* Sometimes, we need to get a shell anyway.

* We _could_ run some SSH server in the container ...

* But it is easier to use `docker exec`.

```bash
$ docker exec -ti ticktock sh
```

* This creates a new process (running `sh`) _inside_ the container.

* This can also be done "manually" with the tool `nsenter`.

---

## Caveats

* The tool that you want to run needs to exist in the container.

* Some tools (like `ip netns exec`) let you attach to _one_ namespace at a time.

  (This lets you e.g. setup network interfaces, even if you don't have `ifconfig` or `ip` in the container.)

* Most importantly: the container needs to be running.

* What if the container is stopped or crashed?

---

## Getting a shell in a stopped container

* A stopped container is only _storage_ (like a disk drive).

* We cannot SSH into a disk drive or USB stick!

* We need to connect the disk to a running machine.

* How does that translate into the container world?

---

## Analyzing a stopped container

As an exercise, we are going to try to find out what's wrong with `jpetazzo/crashtest`.

```bash
docker run jpetazzo/crashtest
```

The container starts, but then stops immediately, without any output.

What would MacGyver&trade; do?

First, let's check the status of that container.

```bash
docker ps -l
```

---

## Viewing filesystem changes

* We can use `docker diff` to see files that were added / changed / removed.

```bash
docker diff <container_id>
```

* The container ID was shown by `docker ps -l`.

* We can also see it with `docker ps -lq`.

* The output of `docker diff` shows some interesting log files!

---

## Accessing files

* We can extract files with `docker cp`.

```bash
docker cp <container_id>:/var/log/nginx/error.log .
```

* Then we can look at that log file.

```bash
cat error.log
```

(The directory `/run/nginx` doesn't exist.)

---

## Exploring a crashed container

* We can restart a container with `docker start` ...

* ... But it will probably crash again immediately!

* We cannot specify a different program to run with `docker start`

* But we can create a new image from the crashed container

```bash
docker commit <container_id> debugimage
```

* Then we can run a new container from that image, with a custom entrypoint

```bash
docker run -ti --entrypoint sh debugimage
```

---

class: extra-details

## Obtaining a complete dump

* We can also dump the entire filesystem of a container.

* This is done with `docker export`.

* It generates a tar archive.

```bash
docker export <container_id> | tar tv
```

This will give a detailed listing of the content of the container.

???

:EN:- Troubleshooting and getting inside a container
:FR:- Inspecter un conteneur en détail, en *live* ou *post-mortem*
