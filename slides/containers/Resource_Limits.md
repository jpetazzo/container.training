# Limiting resources

- So far, we have used containers as convenient units of deployment.

- What happens when a container tries to use more resources than available?

  (RAM, CPU, disk usage, disk and network I/O...)

- What happens when multiple containers compete for the same resource?

- Can we limit resources available to a container?

  (Spoiler alert: yes!)

---

## Container processes are normal processes

- Containers are closer to "fancy processes" than to "lightweight VMs".

- A process running in a container is, in fact, a process running on the host.

- Let's look at the output of `ps` on a container host running 3 containers :

  ```
       0  2662  0.2  0.3 /usr/bin/dockerd -H fd://
       0  2766  0.1  0.1  \_ docker-containerd --config /var/run/docker/containe
       0 23479  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
       0 23497  0.0  0.0      |   \_ `nginx`: master process nginx -g daemon off;
     101 23543  0.0  0.0      |       \_ `nginx`: worker process
       0 23565  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
     102 23584  9.4 11.3      |   \_ `/docker-java-home/jre/bin/java` -Xms2g -Xmx2
       0 23707  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
       0 23725  0.0  0.0          \_ `/bin/sh`
  ```

- The highlighted processes are containerized processes.
  <br/>
  (That host is running nginx, elasticsearch, and alpine.)

---

## By default: nothing changes

- What happens when a process uses too much memory on a Linux system?

--

- Simplified answer:

  - swap is used (if available);

  - if there is not enough swap space, eventually, the out-of-memory killer is invoked;

  - the OOM killer uses heuristics to kill processes;

  - sometimes, it kills an unrelated process.

--

- What happens when a container uses too much memory?

- The same thing!

  (i.e., a process eventually gets killed, possibly in another container.)

---

## Limiting container resources

- The Linux kernel offers rich mechanisms to limit container resources.

- For memory usage, the mechanism is part of the *cgroup* subsystem.

- This subsystem allows limiting the memory for a process or a group of processes.

- A container engine leverages these mechanisms to limit memory for a container.

- The out-of-memory killer has a new behavior:

  - it runs when a container exceeds its allowed memory usage,

  - in that case, it only kills processes in that container.

---

## Limiting memory in practice

- The Docker Engine offers multiple flags to limit memory usage.

- The two most useful ones are `--memory` and `--memory-swap`.

- `--memory` limits the amount of physical RAM used by a container.

- `--memory-swap` limits the total amount (RAM+swap) used by a container.

- The memory limit can be expressed in bytes, or with a unit suffix.

  (e.g.: `--memory 100m` = 100 megabytes.)

- We will see two strategies: limiting RAM usage, or limiting both

---

## Limiting RAM usage

Example:

```bash
docker run -ti --memory 100m python
```

If the container tries to use more than 100 MB of RAM, *and* swap is available:

- the container will not be killed,

- memory above 100 MB will be swapped out,

- in most cases, the app in the container will be slowed down (a lot).

If we run out of swap, the global OOM killer still intervenes.

---

## Limiting both RAM and swap usage

Example:

```bash
docker run -ti --memory 100m --memory-swap 100m python
```

If the container tries to use more than 100 MB of memory, it is killed.

On the other hand, the application will never be slowed down because of swap.

---

## When to pick which strategy?

- Stateful services (like databases) will lose or corrupt data when killed

- Allow them to use swap space, but monitor swap usage

- Stateless services can usually be killed with little impact

- Limit their mem+swap usage, but monitor if they get killed

- Ultimately, this is no different from "do I want swap, and how much?"

---

## Limiting CPU usage

- There are no less than 3 ways to limit CPU usage:

  - setting a relative priority with `--cpu-shares`,

  - setting a CPU% limit with `--cpus`,

  - pinning a container to specific CPUs with `--cpuset-cpus`.

- They can be used separately or together.

---

## Setting relative priority

- Each container has a relative priority used by the Linux scheduler.

- By default, this priority is 1024.

- As long as CPU usage is not maxed out, this has no effect.

- When CPU usage is maxed out, each container receives CPU cycles in proportion of its relative priority.

- In other words: a container with `--cpu-shares 2048` will receive twice as much than the default.

---

## Setting a CPU% limit

- This setting will make sure that a container doesn't use more than a given % of CPU.

- The value is expressed in CPUs; therefore:

  `--cpus 0.1` means 10% of one CPU,

  `--cpus 1.0` means 100% of one whole CPU,

  `--cpus 10.0` means 10 entire CPUs.

---

## Pinning containers to CPUs

- On multi-core machines, it is possible to restrict the execution on a set of CPUs.

- Examples:

  `--cpuset-cpus 0` forces the container to run on CPU 0;

  `--cpuset-cpus 3,5,7` restricts the container to CPUs 3, 5, 7;

  `--cpuset-cpus 0-3,8-11` restricts the container to CPUs 0, 1, 2, 3, 8, 9, 10, 11.

- This will not reserve the corresponding CPUs!

  (They might still be used by other containers, or uncontainerized processes.)

---

## Limiting disk usage

- Most storage drivers do not support limiting the disk usage of containers.

  (With the exception of devicemapper, but the limit cannot be set easily.)
 
- This means that a single container could exhaust disk space for everyone.

- In practice, however, this is not a concern, because:

  - data files (for stateful services) should reside on volumes,

  - assets (e.g. images, user-generated content...) should reside on object stores or on volume,

  - logs are written on standard output and gathered by the container engine.

- Container disk usage can be audited with `docker ps -s` and `docker diff`.
