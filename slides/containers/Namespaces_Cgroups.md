# Deep dive into container internals

In this chapter, we will explain some of the fundamental building blocks of containers.

This will give you a solid foundation so you can:

- understand "what's going on" in complex situations,

- anticipate the behavior of containers (performance, security...) in new scenarios,

- implement your own container engine.

The last item should be done for educational purposes only!

---

## There is no container code in the Linux kernel

- If we search "container" in the Linux kernel code, we find:

  - generic code to manipulate data structures (like linked lists, etc.),

  - unrelated concepts like "ACPI containers",

  - *nothing* relevant to "our" containers!

- Containers are composed using multiple independent features.

- On Linux, containers rely on "namespaces, cgroups, and some filesystem magic."

- Security also requires features like capabilities, seccomp, LSMs...

---

# Control groups

- Control groups provide resource *metering* and *limiting*.

- This covers:

  - "classic" compute resources like memory, CPU, I/O

  - system resources like number of processes (PID)

  - "exotic" resources like GPU VRAM, huge pages, RDMA

  - other things like device node access (`/dev`) and perf events

---

## Crowd control

- Control groups also allow to group processes for special operations:

  - freeze (conceptually similar to a "mass-SIGSTOP/SIGCONT")

  - kill (safe mass-SIGKILL)

---

## Generalities

- Cgroups form a hierarchy (a tree)

- We can create nodes in that hierarchy

- We can associate limits to a node

- We can move a process (or multiple processes) to a leaf

- The process (or processes) will then respect these limits

- We can check the current usage of each node

- In other words: limits are optional (if we only want accounting)

- When a process is created, it is placed in its parent's groups

- The main interface is a pseudo-filesystem (typically mounted on `/sys/fs/cgroup`)

---

## Example

.small[
```bash
$ tree /sys/fs/cgroup/  -d
/sys/fs/cgroup/
├── init.scope
├── machine.slice
├── system.slice
│   ├── avahi-daemon.service
│   ├── ...
│   ├── docker-de3ee38bc8d90b7da218523004cae504a2fa821224fd49f53521d862db583fef.scope
│   ├── docker-e9e55ba69f0a4639793464972a8645cdb23ae9f60567384479a175e3226776b4.scope
│   ├── docker.service
│   ├── docker.socket
│   ├── ...
│   └── wpa_supplicant.service
└── user.slice
    └── user-1000.slice
        ├── session-1.scope
        └── user@1000.service
            ├── app.slice
            │   └── ...
            ├── init.scope
            └── session.slice
                └── ...
```
]

---

class: extra-details, deep-dive

## Cgroups v1 vs v2

- Cgroups v1 were the original implementation

  (back when Docker was created)

- Cgroups v2 are a huge refactor

  (development started in Linux 3.10, released in 4.5.)

- Cgroups v2 have a number of differences:

  - single hierarchy (instead of one tree per controller)

  - processes can only be on leaf nodes (not inner nodes)

  - and of course many improvements / refactorings

- Cgroups v2 should be the default on all modern distros!

---

class: extra-details, deep-dive

## Example of cgroup v1 hierarchy

The numbers are PIDs.

The names are the names of our nodes (arbitrarily chosen).

.small[
```bash
cpu                      memory
├── batch                ├── stateless
│   ├── cryptoscam       │   ├── 25
│   │   └── 52           │   ├── 26
│   └── ffmpeg           │   ├── 27
│       ├── 109          │   ├── 52
│       └── 88           │   ├── 109
└── realtime             │   └── 88
    ├── nginx            └── databases
    │   ├── 25               ├── 1008
    │   ├── 26               └── 524
    │   └── 27
    ├── postgres
    │   └── 524
    └── redis
        └── 1008
```
]

---

## CPU cgroup

- Keeps track of CPU time used by a group of processes

  (this is easier and more accurate than `getrusage` and `/proc`)

- Allows setting relative weights used by the scheduler

- Allows setting maximum time usage per time period

  (e.g. "50ms every 100ms", which would cap the group to 50% of one CPU core)

- Allows setting reservations and caps ("utilization clamping")

  (particularly relevant for realtime processes)

---

## Checking current CPU limits

- Getting the cgroup for the current user session:
  ```bash
  cat /proc/$$/cgroup
  ```
  (it should start with `/user.slice/...`)

- Checking the current CPU limit:
  ```bash
  cat /sys/fs/cgroup/user.slice/.../cpu.max
  ```
  (it should look like `max 100000`)

- `max` means unlimited; `100000` means "over a period of 100000 microseconds"

  (unless specified, all cgroup time durations are in microseconds)

---

## Setting a CPU limit

- Run `top` in a terminal to view CPU usage

- In a separate terminal, burn CPU cycles with e.g.:
  ```bash
  while : ; do : ; done
  ```

- Set a 50% CPU limit for that user or session:
  ```bash
  echo 50000 > /sys/fs/cgroup/user.slice/.../cpu.max
  ```

- Notice that CPU usage goes down

  (probably to *less* than 50% since this is a limit for the whole user/session!)

---

## Removing the CPU limit

- Remember to remove the limit when you're done:
  ```bash
  echo max > /sys/fs/cgroup/user.slice/.../cpu.max
  ```

---

## Cpuset cgroup

- Pin groups to specific CPU(s)

- Features:

  - limit apps to specific CPUs (`cpuset.cpus`)

  - reserve CPUs for exclusive use (`cpuset.cpus.exclusive`)

  - assign apps to specific NUMA memory nodes (`cpuset.mems`)

- Use-cases:

  - dedicate CPUs to avoid performance loss due to cache flushes

  - improve memory performance in NUMA systems

---

## Cpuset concepts

- `cpuset.cpus` / `cpuset.mems`

  *express what we allow the cgroup to use (can be empty to allow everything)*

- `cpuset.cpus.effective` / `cpusets.mems.effective`

  *express what the cgroup can actually use after accounting for other restrictions*

- `cpuset.cpus.exclusive` / `cpuset.cpus.partition`

  *used to create "partitions" = sets of CPU(s) exclusively reserved for a cgroup*

---

## Memory cgroup: accounting

- Keeps track of pages used by each group:

  - file (read/write/mmap from block devices)
  - anonymous (stack, heap, anonymous mmap)
  - active (recently accessed)
  - inactive (candidate for eviction)
  - ...many other categories!

- Each page is "charged" to a single group

  (this can result in non-deterministic "charges" for shared pages, e.g. mapped files)

- To view all the counters kept by this cgroup:

  ```bash
  $ cat /sys/fs/cgroup/memory.stat
  ```

---

## Memory cgroup: limits and reservations

- Cgroups v1 allowed to set soft and hard limits

  (soft limits influenced reclaim but it wasn't straightforward to use)

- Cgroups v2 are way more sophisticated:

  - hard limits (`.max`)

  - thresholds triggering more evictions (`.high`)

  - thresholds triggering less evictions (`.low`)

  - reservations (`.min`)

- Also limits for swap and zswap 

---

## Hard limits

- A cgroup can *never* exceed its hard limits

- When a cgroup tries to use more than the hard limit:

  - the kernel tries to reclaim memory (buffers, mapped files...)

  - when there is nothing to reclaim, the OOM killer is invoked

- There is a `memory.oom.group` flag to alter OOM behavior:

  - `0` (default) = kill processes one by one

  - `1` = consider the cgroup as a unit; OOM will kill it entirely

---

## Also...

- A `.peak` value is also exposed for each tracked amount

  (memory, swap, zswap)

- Write an amount to `memory.reclaim` to trigger reclaim

  (=ask the kernel to recover memory from the cgroup)

- Check memory stats per NUMA nopde (`memory.numa_stat`)

- And more!

---

## Block I/O cgroup

- Keep track of I/Os for each group:

  - per block device

  - read, write, and discard

  - in bytes and in operations

- Set hard limits for each counter

- Set relative weights and latency targets

---

## `io.max`

- Enforce hard limits

  (set max number of operations, of bytes read/written...)

- Each limit is per-device

- Doesn't offer performance guarantees

  (once a device is saturated, performance will degrade for everyone)

---

## `io.cost.qos`

- Try to offer latency guarantees

- Define per-device thresholds to throttle operations

  "if the 95% percentile latency of read operations on this device
  is above 100ms...

  ...throttle operations on this device (queue them)"

- Can also define `io.weight` for relative priorities between cgroups

- Check [this document](https://facebookmicrosites.github.io/resctl-demo-website/docs/demo_docs/setting_benchmarks/iocost/) for some details and hints

---

## Network I/O

- Cgroups v1 had net_cls and net_prio controllers

- These have been deprecated in cgroups v2:

       *There is no direct equivalent of the net_cls and net_prio
       controllers from cgroups version 1.  Instead, support has been
       added to iptables(8) to allow eBPF filters that hook on cgroup v2
       pathnames to make decisions about network traffic on a per-cgroup
       basis.*

---

## Pid

- Limit (and count) number of processes in a cgroup

- Protects against e.g. fork bombs

---

## Devices

- We need to limit access to device nodes

- Containers should not be able to open e.g. disks and partitions directly

  (/dev/sda\*, /dev/nvme\*...)

- However, some devices are expected to be available at all times:

  /dev/tty, /dev/zero, /dev/null, /dev/random...

---

## Cgroups v1

- There used to be a special "devices" control group

- It made it easy to grand read/write/mknod permissions

  (individually for each device and each container)

- Access could be granted/revoked/viewed through a pseudo-file:
  ```bash
  echo 'c 1:3 mr' > /sys/fs/cgroup/.../devices.allow
  ```

- This file doesn't exist anymore in cgroups v2!

---

## Cgroups v2

- Device access is controlled with eBPF programs

  (there is a special program type, [`cgroup_device`][bpf-cgroup-device], for that purpose)

- This requires writing and compiling eBPF programs (😰)

- Viewing permissions requires disassembling eBPF programs (😱)

[bpf-cgroup-device]: https://docs.ebpf.io/linux/program-type/BPF_PROG_TYPE_CGROUP_DEVICE/

---

## Viewing eBPF programs

- Install bpf tools (package name `bpftool` or `bpf`)

- View all eBPF programs attached to cgroups:
  ```bash
  sudo bpftool cgroup tree
  ```

- View eBPF programs attached to a Docker container:
  ```bash
  sudo bpftool cgroup list /sys/fs/cgroup/system.slice/docker-<CONTAINER_ID>.scope
  ```

- Disassemble an eBPF program:
  ```bash
  sudo bpftool prog dump xlated id <ID>
  ```

- *Bon chance* 😬

---

## Some interesting nodes

- `/dev/net/tun` (network interface manipulation)

- `/dev/fuse` (filesystems in user space)

- `/dev/kvm` (run VMs in containers)

- `/dev/dri` (GPU)

- `/dev/ttyUSB*`, `/dev/ttyACM*` (serial devices)

- `/dev/snd/*` (sound cards)

---

## And the exotic ones...

- `rdma`: remote memory access, infiniband

- `dmem`: device memory (VRAM), relatively new

  (kernel 6.14, January 2025; only Intel and AMD GPU for now)

- `hugetlb`: huge pages

- `perf_event`: [performance profiling](https://perfwiki.github.io/main/)

- `misc`: generic cgroup for other discrete resources

  (extension point to plug even more exotic resources)

---

# Namespaces

- Provide processes with their own view of the system

- Namespaces limit what you can see (and therefore, what you can use)

- These namespaces are available in modern kernels:

  - pid
  - net
  - mnt
  - uts
  - ipc
  - user
  - time
  - cgroup

  (we are going to detail them individually)

- Each process belongs to one namespace of each type

---

## Namespaces are always active

- Namespaces exist even when you don't use containers

- This is a bit similar to the UID field in UNIX processes:

  - all processes have the UID field, even if no user exists on the system

  - the field always has a value / the value is always defined
    <br/>
    (i.e. any process running on the system has some UID)

  - the value of the UID field is used when checking permissions
    <br/>
    (the UID field determines which resources the process can access)

- You can replace "UID field" with "namespace" above and it still works!

- In other words: even when you don't use containers,
  <br/>there is one namespace of each type, containing all the processes on the system

---

class: extra-details, deep-dive

## Manipulating namespaces

- Namespaces are created with two methods:

  - the `clone()` system call (used when creating new threads and processes)

  - the `unshare()` system call

- The Linux tool `unshare` allows doing that from a shell

- A new process can re-use none / all / some of the namespaces of its parent

- It is possible to "enter" a namespace with the `setns()` system call

- The Linux tool `nsenter` allows doing that from a shell

---

class: extra-details, deep-dive

## Namespaces lifecycle

- When the last process of a namespace exits, the namespace is destroyed

- All the associated resources are then removed

- Namespaces are materialized by pseudo-files in `/proc/<pid>/ns`.

  ```bash
  ls -l /proc/self/ns
  ```

- It is possible to compare namespaces by checking these files

  (this helps to answer the question, "are these two processes in the same namespace?")

- It is possible to preserve a namespace by bind-mounting its pseudo-file

---

class: extra-details, deep-dive

## Namespaces can be used independently

- As mentioned in the previous slides:

  *a new process can re-use none / all / some of the namespaces of its parent*

- It's possible to create e.g.:

  - mount namespaces to have "private" `/tmp` for each user / app

  - network namespaces to isolate apps or give them a special network access

- It's possible to use namespaces without cgroups

  (and totally outside of container contexts)

---

## UTS namespace

- gethostname / sethostname

- Allows setting a custom hostname for a container

- That's (mostly) it!

- Also allows setting the NIS domain

  (if you don't know what a NIS domain is, you don't have to worry about it!)

- If you're wondering: UTS = UNIX time sharing

- This namespace was named like this because of the `struct utsname`,
  <br/>
  which is commonly used to obtain the machine's hostname, architecture, etc.

  (the more you know!)

---

class: extra-details, deep-dive

## Creating our first namespace

Let's use `unshare` to create a new process that will have its own UTS namespace:

```bash
$ sudo unshare --uts
```

- We have to use `sudo` for most `unshare` operations

- We indicate that we want a new uts namespace, and nothing else

- If we don't specify a program to run, a `$SHELL` is started

---

class: extra-details, deep-dive

## Demonstrating our uts namespace

In our new "container", check the hostname, change it, and check it:

```bash
 # hostname
 nodeX
 # hostname tupperware
 # hostname
 tupperware
```

In another shell, check that the machine's hostname hasn't changed:

```bash
$ hostname
nodeX
```

Exit the "container" with `exit` or `Ctrl-D`.

---

## Net namespace overview

- Each network namespace has its own private network stack

- The network stack includes:

  - network interfaces (including `lo`)

  - routing table**s** (as in `ip rule` etc.)

  - iptables chains and rules

  - sockets (as seen by `ss`, `netstat`)

- You can move a network interface from a network namespace to another:
  ```bash
  ip link set dev eth0 netns PID
  ```

---

## Net namespace typical use

- Each container is given its own network namespace

- For each network namespace (i.e. each container), a `veth` pair is created

  (two `veth` interfaces act as if they were connected with a cross-over cable)

- One `veth` is moved to the container network namespace (and renamed `eth0`)

- The other `veth` is moved to a bridge on the host (e.g. the `docker0` bridge)

---

class: extra-details

## Creating a network namespace

Start a new process with its own network namespace:

```bash
$ sudo unshare --net
```

See that this new network namespace is unconfigured:

```bash
 # ping 1.1
 connect: Network is unreachable
 # ifconfig
 # ip link ls
 1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

---

class: extra-details

## Creating the `veth` interfaces

In another shell (on the host), create a `veth` pair:

```bash
$ sudo ip link add name in_host type veth peer name in_netns
```

Configure the host side (`in_host`):

```bash
$ sudo ip link set in_host up
$ sudo ip addr add 172.22.0.1/24 dev in_host
```

---

class: extra-details

## Moving the `veth` interface

*In the process created by `unshare`,* check the PID of our "network container":

```bash
 # echo $$
 533
```

*On the host*, move the other side (`in_netns`) to the network namespace:

```bash
$ sudo ip link set in_netns netns 533
```

(Make sure to update "533" with the actual PID obtained above!)

---

class: extra-details

## Basic network configuration

Let's set up `lo` (the loopback interface):

```bash
 # ip link set lo up
```

Activate the `veth` interface and rename it to `eth0`:

```bash
 # ip link set in_netns name eth0 up
```

---

class: extra-details

## Allocating IP address and default route

*In the process created by `unshare`,* configure the interface:

```bash
 # ip addr add 172.22.0.2/24 dev eth0
 # ip route add default via 172.22.0.1
```

(Make sure to update the IP addresses if necessary.)

Check that we can ping the host:

```bash
 # ping 172.22.0.1
```

---

class: extra-details

## Reaching the outside world

This requires to:

- enable forwarding on the host

- add a masquerading (SNAT) rule for traffic coming from the namespace

If Docker is running on the host, we can also add the `in_host` interface
to the Docker bridge, and configure the `in_netns` interface with an
IP address belonging to the subnet of the Docker bridge!

---

class: extra-details

## Cleaning up network namespaces

- Terminate the process created by `unshare` (with `exit` or `Ctrl-D`).

- Since this was the only process in the network namespace, it is destroyed.

- All the interfaces in the network namespace are destroyed.

- When a `veth` interface is destroyed, it also destroys the other half of the pair.

- So we don't have anything else to do to clean up!

---

## Docker options leveraging network namespaces

- `--net none` gives an empty network namespace to a container

  (effectively isolating it completely from the network)

- `--net host` means "do not containerize the network"

  (no network namespace is created; the container uses the host network stack)

- `--net container` means "reuse the network namespace of another container"

  (as a result, both containers share the same interfaces, routes, etc.)

---

## Mnt namespace

- Processes can have their own root fs (à la chroot)

- Processes can also have "private" mounts; this allows:

  - isolating `/tmp` (per user, per service...)

  - masking `/proc`, `/sys` (for processes that don't need them)

  - mounting remote filesystems or sensitive data,
    <br/>but make it visible only for allowed processes

- Mounts can be totally private, or shared

- For a long time, there was no easy way to "move" a mount to another namespace

- It's now possible; see [justincormack/addmount](https://github.com/justincormack/addmount) for a simple example

---

class: extra-details, deep-dive

## Setting up a private `/tmp`

Create a new mount namespace:

```bash
$ sudo unshare --mount
```

In that new namespace, mount a brand new `/tmp`:

```bash
 # mount -t tmpfs none /tmp
```

Check the content of `/tmp` in the new namespace, and compare to the host.

The mount is automatically cleaned up when you exit the process.

---

## PID namespace

- Processes within a PID namespace only "see" processes
  in the same PID namespace

- Each PID namespace has its own numbering (starting at 1)

- When PID 1 goes away, the whole namespace is killed

  (when PID 1 goes away on a normal UNIX system, the kernel panics!)

- Those namespaces can be nested

- A process ends up having multiple PIDs (one per namespace in which it is nested)

---

class: extra-details, deep-dive

## PID namespace in action

Create a new PID namespace:

```bash
$ sudo unshare --pid --fork
```

(We need the `--fork` flag because the PID namespace is special.)

Check the process tree in the new namespace:

```bash
 # ps faux
```

--

class: extra-details, deep-dive

🤔 Why do we see all the processes?!?

---

class: extra-details, deep-dive

## PID namespaces and `/proc`

- Tools like `ps` rely on the `/proc` pseudo-filesystem

- Our new namespace still has access to the original `/proc`

- Therefore, it still sees host processes

- But it cannot affect them

  (try to `kill` a process: you will get `No such process`)

---

class: extra-details, deep-dive

## PID namespaces, take 2

- This can be solved by mounting `/proc` in the namespace

- The `unshare` utility provides a convenience flag, `--mount-proc`

- This flag will mount `/proc` in the namespace

- It will also unshare the mount namespace, so that this mount is local

Try it:

```bash
 $ sudo unshare --pid --fork --mount-proc
 # ps faux
```

---

class: extra-details

## OK, really, why do we need `--fork`?

*It is not necessary to remember all these details.
<br/>
This is just an illustration of the complexity of namespaces!*

The `unshare` tool calls the `unshare` syscall, then `exec`s the new binary.
<br/>
A process calling `unshare` to create new namespaces is moved to the new namespaces...
<br/>
... Except for the PID namespace.
<br/>
(Because this would change the current PID of the process from X to 1.)

The processes created by the new binary are placed into the new PID namespace.
<br/>
The first one will be PID 1.
<br/>
If PID 1 exits, it is not possible to create additional processes in the namespace.
<br/>
(Attempting to do so will result in `ENOMEM`.)

Without the `--fork` flag, the first command that we execute will be PID 1 ...
<br/>
... And once it exits, we cannot create more processes in the namespace!

Check `man 2 unshare` and `man pid_namespaces` if you want more details.

---

## IPC namespace

--

- Does anybody know about IPC?

--

- Does anybody *care* about IPC?

--

- Allows a process (or group of processes) to have own:

  - IPC semaphores
  - IPC message queues
  - IPC shared memory

  ... without risk of conflict with other instances.

- Older versions of PostgreSQL cared about this.

*No demo for that one.*

---

## User namespace

- Allows mapping UID/GID; e.g.:

  - UID 0→1999 in container C1 is mapped to UID 10000→11999 on host
  - UID 0→1999 in container C2 is mapped to UID 12000→13999 on host
  - etc.

- UID 0 in the container can still perform privileged operations in the container

  (for instance: setting up network interfaces)

- But outside of the container, it is a non-privileged user

- It also means that the UID in containers becomes unimportant

  (just use UID 0 in the container, since it gets squashed to a non-privileged user outside)

- Ultimately enables better privilege separation in container engines

---

class: extra-details, deep-dive

## User namespace challenges

- UID needs to be mapped when passed between processes or kernel subsystems

- Filesystem permissions and file ownership are more complicated

  .small[(e.g. when the same root filesystem is shared by multiple containers
  running with different UIDs)]

- With the Docker Engine:

  - some feature combinations are not allowed
    <br/>
    (e.g. user namespace + host network namespace sharing)

  - user namespaces need to be enabled/disabled globally
    <br/>
    (when the daemon is started)

  - container images are stored separately
    <br/>
    (so the first time you toggle user namespaces, you need to re-pull images)

*No demo for that one.*

---

## Time namespace

- Virtualize time

- Expose a slower/faster clock to some processes

  (for e.g. simulation purposes)

- Expose a clock offset to some processes

  (simulation, suspend/restore...)

---

## Cgroup namespace

- Virtualize access to `/proc/<PID>/cgroup`

- Lets containerized processes view their relative cgroup tree

---

# Security features

- Namespaces and cgroups are not enough to ensure strong security

- We need extra mechanisms: capabilities, seccomp, LSMs

- These mechanisms were already used before containers to harden security

- They can be used together with containers

- Good container engines will automatically leverage these features.

  (so that you don't have to worry about it)

---

## Capabilities

- In traditional UNIX, many operations are possible if and only if UID=0 (root)

- Some of these operations are very powerful:

  - changing file ownership, accessing all files ...

- Some of these operations deal with system configuration, but can be abused:

  - setting up network interfaces, mounting filesystems ...

- Some of these operations are not very dangerous but are needed by servers:

  - binding to a port below 1024.

- Capabilities are per-process flags to allow these operations individually

---

## Some capabilities

- `CAP_CHOWN`: arbitrarily change file ownership and permissions

- `CAP_DAC_OVERRIDE`: arbitrarily bypass file ownership and permissions

- `CAP_NET_ADMIN`: configure network interfaces, iptables rules, etc.

- `CAP_NET_BIND_SERVICE`: bind a port below 1024

See `man capabilities` for the full list and details

---

## Using capabilities

- Container engines will typically drop all "dangerous" capabilities

- You can then re-enable capabilities on a per-container basis, as needed

- With the Docker engine: `docker run --cap-add ...`

- From the shell:

  `capsh --drop=cap_net_admin --`

  `capsh --drop=all --`

---

## File capabilities

- It is also possible to give capabilities to executable files

- This is comparable to the SUID bit, but with finer grain

  (e.g., `setcap cap_net_raw+ep /bin/ping`)

- There are differences between *permitted* and *inheritable* capabilities...

  🤔

---

class: extra-details

## Capability sets

- Permitted set (=what a process could use, provided the file has the cap)

- Effective set (=what a process can actually use)

- Inheritable set (=capabilities preserved across exexcve calls)

- Bounding set (=system-wide limit over what can be acquired through execve / capset)

- Ambient set (=capabilities retained across execve for non-privileged users)

- Files can have *permitted*, *effective*, *inheritable* capability sets

---

## More about capabilities

- Capabilities manpage:

  https://man7.org/linux/man-pages/man7/capabilities.7.html

- Subtleties about `capsh`:

  https://sites.google.com/site/fullycapable/why-didnt-that-work

---

## Seccomp

- Seccomp is secure computing.

- Achieve high level of security by restricting drastically available syscalls.

- Original seccomp only allows `read()`, `write()`, `exit()`, `sigreturn()`.

- The seccomp-bpf extension allows specifying custom filters with BPF rules.

- This allows filtering by syscall, and by parameter.

- BPF code can perform arbitrarily complex checks, quickly, and safely.

- Container engines take care of this so you don't have to.

---

## Linux Security Modules

- The most popular ones are SELinux and AppArmor.

- Red Hat distros generally use SELinux.

- Debian distros (in particular, Ubuntu) generally use AppArmor.

- LSMs add a layer of access control to all process operations.

- Container engines take care of this so you don't have to.

???

:EN:Containers internals
:EN:- Control groups (cgroups)
:EN:- Linux kernel namespaces
:FR:Fonctionnement interne des conteneurs
:FR:- Les "control groups" (cgroups)
:FR:- Les namespaces du noyau Linux
