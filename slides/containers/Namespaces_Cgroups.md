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

- This covers a number of "usual suspects" like:

  - memory

  - CPU

  - block I/O

  - network (with cooperation from iptables/tc)

- And a few exotic ones:

  - huge pages (a special way to allocate memory)

  - RDMA (resources specific to InfiniBand / remote memory transfer)

---

## Crowd control

- Control groups also allow to group processes for special operations:

  - freezer (conceptually similar to a "mass-SIGSTOP/SIGCONT")

  - perf_event (gather performance events on multiple processes)

  - cpuset (limit or pin processes to specific CPUs)

- There is a "pids" cgroup to limit the number of processes in a given group.

- There is also a "devices" cgroup to control access to device nodes.

  (i.e. everything in `/dev`.)

---

## Generalities

- Cgroups form a hierarchy (a tree).

- We can create nodes in that hierarchy.

- We can associate limits to a node.

- We can move a process (or multiple processes) to a node.

- The process (or processes) will then respect these limits.

- We can check the current usage of each node.

- In other words: limits are optional (if we only want accounting).

- When a process is created, it is placed in its parent's groups.

---

## Example

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

class: extra-details, deep-dive

## Cgroups v1 vs v2

- Cgroups v1 are available on all systems (and widely used).

- Cgroups v2 are a huge refactor.

  (Development started in Linux 3.10, released in 4.5.)

- Cgroups v2 have a number of differences:

  - single hierarchy (instead of one tree per controller),

  - processes can only be on leaf nodes (not inner nodes),

  - and of course many improvements / refactorings.

- Cgroups v2 enabled by default on Fedora 31 (2019), Ubuntu 21.10...

---

## Memory cgroup: accounting

- Keeps track of pages used by each group:

  - file (read/write/mmap from block devices),
  - anonymous (stack, heap, anonymous mmap),
  - active (recently accessed),
  - inactive (candidate for eviction).

- Each page is "charged" to a group.

- Pages can be shared across multiple groups.

  (Example: multiple processes reading from the same files.)

- To view all the counters kept by this cgroup:

  ```bash
  $ cat /sys/fs/cgroup/memory/memory.stat
  ```

---

## Memory cgroup v1: limits

- Each group can have (optional) hard and soft limits.

- Limits can be set for different kinds of memory:

  - physical memory,

  - kernel memory,

  - total memory (including swap).

---

## Soft limits and hard limits

- Soft limits are not enforced.

  (But they influence reclaim under memory pressure.)

- Hard limits *cannot* be exceeded:

  - if a group of processes exceeds a hard limit,

  - and if the kernel cannot reclaim any memory,

  - then the OOM (out-of-memory) killer is triggered,

  - and processes are killed until memory gets below the limit again.

---

class: extra-details, deep-dive

## Avoiding the OOM killer

- For some workloads (databases and stateful systems), killing
  processes because we run out of memory is not acceptable.

- The "oom-notifier" mechanism helps with that.

- When "oom-notifier" is enabled and a hard limit is exceeded:

  - all processes in the cgroup are frozen,

  - a notification is sent to user space (instead of killing processes),

  - user space can then raise limits, migrate containers, etc.,

  - once the memory usage is below the hard limit, unfreeze the cgroup.

---

class: extra-details, deep-dive

## Overhead of the memory cgroup

- Each time a process grabs or releases a page, the kernel update counters.

- This adds some overhead.

- Unfortunately, this cannot be enabled/disabled per process.

- It has to be done system-wide, at boot time.

- Also, when multiple groups use the same page:

  - only the first group gets "charged",

  - but if it stops using it, the "charge" is moved to another group.

---

class: extra-details, deep-dive

## Setting up a limit with the memory cgroup

Create a new memory cgroup:

```bash
$ CG=/sys/fs/cgroup/memory/onehundredmegs
$ sudo mkdir $CG
```

Limit it to approximately 100MB of memory usage:

```bash
$ sudo tee $CG/memory.memsw.limit_in_bytes <<< 100000000
```

Move the current process to that cgroup:

```bash
$ sudo tee $CG/tasks <<< $$
```

The current process *and all its future children* are now limited.

(Confused about `<<<`? Look at the next slide!)

---

class: extra-details, deep-dive

## What's `<<<`?

- This is a "here string". (It is a non-POSIX shell extension.)

- The following commands are equivalent:

  ```bash
  foo <<< hello
  ```

  ```bash
  echo hello | foo
  ```

  ```bash
  foo <<EOF
  hello
  EOF
  ```

- Why did we use that?

---

class: extra-details, deep-dive

## Writing to cgroups pseudo-files requires root

Instead of:

```bash
sudo tee $CG/tasks <<< $$
```

We could have done:

```bash
sudo sh -c "echo $$ > $CG/tasks"
```

The following commands, however, would be invalid:

```bash
sudo echo $$ > $CG/tasks
```

```bash
sudo -i # (or su)
echo $$ > $CG/tasks
```

---

class: extra-details, deep-dive

## Testing the memory limit

Start the Python interpreter:

```bash
$ python
Python 3.6.4 (default, Jan  5 2018, 02:35:40)
[GCC 7.2.1 20171224] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

Allocate 80 megabytes:

```python
>>> s = "!" * 1000000 * 80
```

Add 20 megabytes more:

```python
>>> t = "!" * 1000000 * 20
Killed
```

---

## Memory cgroup v2: limits

- `memory.min` = hard reservation (guaranteed memory for this cgroup)

- `memory.low` = soft reservation ("*try* not to reclaim memory if we're below this")

- `memory.high` = soft limit (aggressively reclaim memory; don't trigger OOMK)

- `memory.max` = hard limit (triggers OOMK)

- `memory.swap.high` = aggressively reclaim memory when using that much swap

- `memory.swap.max` = prevent using more swap than this

---

## CPU cgroup

- Keeps track of CPU time used by a group of processes.

  (This is easier and more accurate than `getrusage` and `/proc`.)

- Keeps track of usage per CPU as well.

  (i.e., "this group of process used X seconds of CPU0 and Y seconds of CPU1".)

- Allows setting relative weights used by the scheduler.

---

## Cpuset cgroup

- Pin groups to specific CPU(s).

- Use-case: reserve CPUs for specific apps.

- Warning: make sure that "default" processes aren't using all CPUs!

- CPU pinning can also avoid performance loss due to cache flushes.

- This is also relevant for NUMA systems.

- Provides extra dials and knobs.

  (Per zone memory pressure, process migration costs...)

---

## Blkio cgroup

- Keeps track of I/Os for each group:

  - per block device
  - read vs write
  - sync vs async

- Set throttle (limits) for each group:

  - per block device
  - read vs write
  - ops vs bytes

- Set relative weights for each group.

- Note: most writes go through the page cache.
  <br/>(So classic writes will appear to be unthrottled at first.)

---

## Net_cls and net_prio cgroup

- Only works for egress (outgoing) traffic.

- Automatically set traffic class or priority
  for traffic generated by processes in the group.

- Net_cls will assign traffic to a class.

- Classes have to be matched with tc or iptables, otherwise traffic just flows normally.

- Net_prio will assign traffic to a priority.

- Priorities are used by queuing disciplines.

---

## Devices cgroup

- Controls what the group can do on device nodes

- Permissions include read/write/mknod

- Typical use:

  - allow `/dev/{tty,zero,random,null}` ...
  - deny everything else

- A few interesting nodes:

  - `/dev/net/tun` (network interface manipulation)
  - `/dev/fuse` (filesystems in user space)
  - `/dev/kvm` (VMs in containers, yay inception!)
  - `/dev/dri` (GPU)

---

# Namespaces

- Provide processes with their own view of the system.

- Namespaces limit what you can see (and therefore, what you can use).

- These namespaces are available in modern kernels:

  - pid
  - net
  - mnt
  - uts
  - ipc
  - user
  - time
  - cgroup

  (We are going to detail them individually.)

- Each process belongs to one namespace of each type.

---

## Namespaces are always active

- Namespaces exist even when you don't use containers.

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
  <br/>there is one namespace of each type, containing all the processes on the system.

---

class: extra-details, deep-dive

## Manipulating namespaces

- Namespaces are created with two methods:

  - the `clone()` system call (used when creating new threads and processes),

  - the `unshare()` system call.

- The Linux tool `unshare` allows doing that from a shell.

- A new process can re-use none / all / some of the namespaces of its parent.

- It is possible to "enter" a namespace with the `setns()` system call.

- The Linux tool `nsenter` allows doing that from a shell.

---

class: extra-details, deep-dive

## Namespaces lifecycle

- When the last process of a namespace exits, the namespace is destroyed.

- All the associated resources are then removed.

- Namespaces are materialized by pseudo-files in `/proc/<pid>/ns`.

  ```bash
  ls -l /proc/self/ns
  ```

- It is possible to compare namespaces by checking these files.

  (This helps to answer the question, "are these two processes in the same namespace?")

- It is possible to preserve a namespace by bind-mounting its pseudo-file.

---

class: extra-details, deep-dive

## Namespaces can be used independently

- As mentioned in the previous slides:

  *A new process can re-use none / all / some of the namespaces of its parent.*

- We are going to use that property in the examples in the next slides.

- We are going to present each type of namespace.

- For each type, we will provide an example using only that namespace.

---

## UTS namespace

- gethostname / sethostname

- Allows setting a custom hostname for a container.

- That's (mostly) it!

- Also allows setting the NIS domain.

  (If you don't know what a NIS domain is, you don't have to worry about it!)

- If you're wondering: UTS = UNIX time sharing.

- This namespace was named like this because of the `struct utsname`,
  <br/>
  which is commonly used to obtain the machine's hostname, architecture, etc.

  (The more you know!)

---

class: extra-details, deep-dive

## Creating our first namespace

Let's use `unshare` to create a new process that will have its own UTS namespace:

```bash
$ sudo unshare --uts
```

- We have to use `sudo` for most `unshare` operations.

- We indicate that we want a new uts namespace, and nothing else.

- If we don't specify a program to run, a `$SHELL` is started.

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

- Each network namespace has its own private network stack.

- The network stack includes:

  - network interfaces (including `lo`),

  - routing table**s** (as in `ip rule` etc.),

  - iptables chains and rules,

  - sockets (as seen by `ss`, `netstat`).

- You can move a network interface from a network namespace to another:
  ```bash
  ip link set dev eth0 netns PID
  ```

---

## Net namespace typical use

- Each container is given its own network namespace.

- For each network namespace (i.e. each container), a `veth` pair is created.

  (Two `veth` interfaces act as if they were connected with a cross-over cable.)

- One `veth` is moved to the container network namespace (and renamed `eth0`).

- The other `veth` is moved to a bridge on the host (e.g. the `docker0` bridge).

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
$ sudo ip link set in_host master docker0 up
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

*On the host*, check the address of the Docker bridge:

```bash
$ ip addr ls dev docker0
```

(It could be something like `172.17.0.1`.)

Pick an IP address in the middle of the same subnet, e.g. `172.17.0.99`.

*In the process created by `unshare`,* configure the interface:

```bash
 # ip addr add 172.17.0.99/24 dev eth0
 # ip route add default via 172.17.0.1
```

(Make sure to update the IP addresses if necessary.)

---

class: extra-details

## Validating the setup

Check that we now have connectivity:

```bash
 # ping 1.1
```

Note: we were able to take a shortcut, because Docker is running,
and provides us with a `docker0` bridge and a valid `iptables` setup.

If Docker is not running, you will need to take care of this!

---

class: extra-details

## Cleaning up network namespaces

- Terminate the process created by `unshare` (with `exit` or `Ctrl-D`).

- Since this was the only process in the network namespace, it is destroyed.

- All the interfaces in the network namespace are destroyed.

- When a `veth` interface is destroyed, it also destroys the other half of the pair.

- So we don't have anything else to do to clean up!

---

## Other ways to use network namespaces

- `--net none` gives an empty network namespace to a container.

  (Effectively isolating it completely from the network.)

- `--net host` means "do not containerize the network".

  (No network namespace is created; the container uses the host network stack.)

- `--net container` means "reuse the network namespace of another container".

  (As a result, both containers share the same interfaces, routes, etc.)

---

## Mnt namespace

- Processes can have their own root fs (à la chroot).

- Processes can also have "private" mounts. This allows:

  - isolating `/tmp` (per user, per service...)

  - masking `/proc`, `/sys` (for processes that don't need them)

  - mounting remote filesystems or sensitive data,
    <br/>but make it visible only for allowed processes

- Mounts can be totally private, or shared.

- At this point, there is no easy way to pass along a mount
  from a namespace to another.

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
  in the same PID namespace.

- Each PID namespace has its own numbering (starting at 1).

- When PID 1 goes away, the whole namespace is killed.

  (When PID 1 goes away on a normal UNIX system, the kernel panics!)

- Those namespaces can be nested.

- A process ends up having multiple PIDs (one per namespace in which it is nested).

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

- Tools like `ps` rely on the `/proc` pseudo-filesystem.

- Our new namespace still has access to the original `/proc`.

- Therefore, it still sees host processes.

- But it cannot affect them.

  (Try to `kill` a process: you will get `No such process`.)

---

class: extra-details, deep-dive

## PID namespaces, take 2

- This can be solved by mounting `/proc` in the namespace.

- The `unshare` utility provides a convenience flag, `--mount-proc`.

- This flag will mount `/proc` in the namespace.

- It will also unshare the mount namespace, so that this mount is local.

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

- UID 0 in the container can still perform privileged operations in the container.

  (For instance: setting up network interfaces.)

- But outside of the container, it is a non-privileged user.

- It also means that the UID in containers becomes unimportant.

  (Just use UID 0 in the container, since it gets squashed to a non-privileged user outside.)

- Ultimately enables better privilege separation in container engines.

---

class: extra-details, deep-dive

## User namespace challenges

- UID needs to be mapped when passed between processes or kernel subsystems.

- Filesystem permissions and file ownership are more complicated.

  .small[(E.g. when the same root filesystem is shared by multiple containers
  running with different UIDs.)]

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

- Namespaces and cgroups are not enough to ensure strong security.

- We need extra mechanisms: capabilities, seccomp, LSMs.

- These mechanisms were already used before containers to harden security.

- They can be used together with containers.

- Good container engines will automatically leverage these features.

  (So that you don't have to worry about it.)

---

## Capabilities

- In traditional UNIX, many operations are possible if and only if UID=0 (root).

- Some of these operations are very powerful:

  - changing file ownership, accessing all files ...

- Some of these operations deal with system configuration, but can be abused:

  - setting up network interfaces, mounting filesystems ...

- Some of these operations are not very dangerous but are needed by servers:

  - binding to a port below 1024.

- Capabilities are per-process flags to allow these operations individually.

---

## Some capabilities

- `CAP_CHOWN`: arbitrarily change file ownership and permissions.

- `CAP_DAC_OVERRIDE`: arbitrarily bypass file ownership and permissions.

- `CAP_NET_ADMIN`: configure network interfaces, iptables rules, etc.

- `CAP_NET_BIND_SERVICE`: bind a port below 1024.

See `man capabilities` for the full list and details.

---

## Using capabilities

- Container engines will typically drop all "dangerous" capabilities.

- You can then re-enable capabilities on a per-container basis, as needed.

- With the Docker engine: `docker run --cap-add ...`

- If you write your own code to manage capabilities:

  - make sure that you understand what each capability does,

  - read about *ambient* capabilities as well.

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
