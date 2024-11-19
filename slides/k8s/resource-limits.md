# Resource Limits

- We can attach resource indications to our pods

  (or rather: to the *containers* in our pods)

- We can specify *limits* and/or *requests*

- We can specify quantities of CPU and/or memory and/or ephemeral storage

---

## Requests vs limits

- *Requests* are *guaranteed reservations* of resources

- They are used for scheduling purposes

- Kubelet will use cgroups to e.g. guarantee a minimum amount of CPU time

- A container **can** use more than its requested resources

- A container using *less* than what it requested should never be killed or throttled

- A node **cannot** be overcommitted with requests

  (the sum of all requests **cannot** be higher than resources available on the node)

- A small amount of resources is set aside for system components

  (this explains why there is a difference between "capacity" and "allocatable")

---

## Requests vs limits

- *Limits* are "hard limits" (a container **cannot** exceed its limits)

- They aren't taken into account by the scheduler

- A container exceeding its memory limit is killed instantly

  (by the kernel out-of-memory killer)

- A container exceeding its CPU limit is throttled

- A container exceeding its disk limit is killed

  (usually with a small delay, since this is checked periodically by kubelet)

- On a given node, the sum of all limits **can** be higher than the node size

---

## Compressible vs incompressible resources

- CPU is a *compressible resource*

  - it can be preempted immediately without adverse effect

  - if we have N CPU and need 2N, we run at 50% speed

- Memory is an *incompressible resource*

  - it needs to be swapped out to be reclaimed; and this is costly

  - if we have N GB RAM and need 2N, we might run at... 0.1% speed!

- Disk is also an *incompressible resource*

  - when the disk is full, writes will fail

  - applications may or may not crash but persistent apps will be in trouble

---

## Running low on CPU

- Two ways for a container to "run low" on CPU:

  - it's hitting its CPU limit

  - all CPUs on the node are at 100% utilization

- The app in the container will run slower

  (compared to running without a limit, or if CPU cycles were available)

- No other consequence

  (but this could affect SLA/SLO for latency-sensitive applications!)

---

class: extra-details

## CPU limits implementation details

- A container with a CPU limit will be "rationed" by the kernel

- Every `cfs_period_us`, it will receive a CPU quota, like an "allowance"

  (that interval defaults to 100ms)

- Once it has used its quota, it will be stalled until the next period

- This can easily result in throttling for bursty workloads

  (see details on next slide)

---

class: extra-details

## A bursty example

- Web service receives one request per minute

- Each request takes 1 second of CPU

- Average load: 1.66%

- Let's say we set a CPU limit of 10%

- This means CPU quotas of 10ms every 100ms

- Obtaining the quota for 1 second of CPU will take 10 seconds

- Observed latency will be 10 seconds (... actually 9.9s) instead of 1 second

  (real-life scenarios will of course be less extreme, but they do happen!)

---

class: extra-details

## Multi-core scheduling details

- Each core gets a small share of the container's CPU quota

  (this avoids locking and contention on the "global" quota for the container)

- By default, the kernel distributes that quota to CPUs in 5ms increments

  (tunable with `kernel.sched_cfs_bandwidth_slice_us`)

- If a containerized process (or thread) uses up its local CPU quota:

  *it gets more from the "global" container quota (if there's some left)*

- If it "yields" (e.g. sleeps for I/O) before using its local CPU quota:

  *the quota is **soon** returned to the "global" container quota, **minus** 1ms*

---

class: extra-details

## Low quotas on machines with many cores

- The local CPU quota is not immediately returned to the global quota

  - this reduces locking and contention on the global quota

  - but this can cause starvation when many threads/processes become runnable

- That 1ms that "stays" on the local CPU quota is often useful

  - if the thread/process becomes runnable, it can be scheduled immediately

  - again, this reduces locking and contention on the global quota

  - but if the thread/process doesn't become runnable, it is wasted!

  - this can become a huge problem on machines with many cores

---

class: extra-details

## CPU limits in a nutshell

- Beware if you run small bursty workloads on machines with many cores!

  ("highly-threaded, user-interactive, non-cpu bound applications")

- Check the `nr_throttled` and `throttled_time` metrics in `cpu.stat`

- Possible solutions/workarounds:

  - be generous with the limits

  - make sure your kernel has the [appropriate patch](https://lkml.org/lkml/2019/5/17/581)

  - use [static CPU manager policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy)

For more details, check [this blog post](https://erickhun.com/posts/kubernetes-faster-services-no-cpu-limits/) or these: ([part 1](https://engineering.indeedblog.com/blog/2019/12/unthrottled-fixing-cpu-limits-in-the-cloud/), [part 2](https://engineering.indeedblog.com/blog/2019/12/cpu-throttling-regression-fix/)).

---

## Running low on memory

- When the kernel runs low on memory, it starts to reclaim used memory

- Option 1: free up some buffers and caches

  (fastest option; might affect performance if cache memory runs very low)

- Option 2: swap, i.e. write to disk some memory of one process to give it to another

  (can have a huge negative impact on performance because disks are slow)

- Option 3: terminate a process and reclaim all its memory

  (OOM or Out Of Memory Killer on Linux)

---

## Memory limits on Kubernetes

- Kubernetes *does not support swap*

  (but it may support it in the future, thanks to [KEP 2400])

- If a container exceeds its memory *limit*, it gets killed immediately

- If a node memory usage gets too high, it will *evict* some pods

  (we say that the node is "under pressure", more on that in a bit!)

[KEP 2400]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/2400-node-swap/README.md#implementation-history

---

## Running low on disk

- When the kubelet runs low on disk, it starts to reclaim disk space

  (similarly to what the kernel does, but in different categories)

- Option 1: garbage collect dead pods and containers

  (no consequence, but their logs will be deleted)

- Option 2: remove unused images

  (no consequence, but these images will have to be repulled if we need them later)

- Option 3: evict pods and remove them to reclaim their disk usage

- Note: this only applies to *ephemeral storage*, not to e.g. Persistent Volumes!

---

## Ephemeral storage?

- This includes:

  - the *read-write layer* of the container
    <br/>
    (any file creation/modification outside of its volumes)

  - `emptyDir` volumes mounted in the container

  - the container logs stored on the node

- This does not include:

  - the container image

  - other types of volumes (e.g. Persistent Volumes, `hostPath`, or `local` volumes)

---

class: extra-details

## Disk limit enforcement

- Disk usage is periodically measured by kubelet

  (with something equivalent to `du`)

- There can be a small delay before pod termination when disk limit is exceeded

- It's also possible to enable filesystem *project quotas*

  (e.g. with EXT4 or XFS)

- Remember that container logs are also accounted for!

  (container log rotation/retention is managed by kubelet)

---

class: extra-details

## `nodefs` and `imagefs`

- `nodefs` is the main filesystem of the node

  (holding, notably, `emptyDir` volumes and container logs)

- Optionally, the container engine can be configured to use an `imagefs`

- `imagefs` will store container images and container writable layers

- When there is a separate `imagefs`, its disk usage is tracked independently

- If `imagefs` usage gets too high, kubelet will remove old images first

  (conversely, if `nodefs` usage gets too high, kubelet won't remove old images)

---

class: extra-details

## CPU and RAM reservation

- Kubernetes passes resources requests and limits to the container engine

- The container engine applies these requests and limits with specific mechanisms

- Example: on Linux, this is typically done with control groups aka cgroups

- Most systems use cgroups v1, but cgroups v2 are slowly being rolled out

  (e.g. available in Ubuntu 22.04 LTS)

- Cgroups v2 have new, interesting features for memory control:

  - ability to set "minimum" memory amounts (to effectively reserve memory)

  - better control on the amount of swap used by a container

---

class: extra-details

## What's the deal with swap?

- With cgroups v1, it's not possible to disable swap for a cgroup

  (the closest option is to [reduce "swappiness"](https://unix.stackexchange.com/questions/77939/turning-off-swapping-for-only-one-process-with-cgroups))

- It is possible with cgroups v2 (see the [kernel docs](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) and the [fbatx docs](https://facebookmicrosites.github.io/cgroup2/docs/memory-controller.html#using-swap))

- Cgroups v2 aren't widely deployed yet

- The architects of Kubernetes wanted to ensure that Guaranteed pods never swap

- The simplest solution was to disable swap entirely

- Kubelet will refuse to start if it detects that swap is enabled!

---

## Alternative point of view

- Swap enables paging¹ of anonymous² memory

- Even when swap is disabled, Linux will still page memory for:

  - executables, libraries

  - mapped files

- Disabling swap *will reduce performance and available resources*

- For a good time, read [kubernetes/kubernetes#53533](https://github.com/kubernetes/kubernetes/issues/53533)

- Also read this [excellent blog post about swap](https://jvns.ca/blog/2017/02/17/mystery-swap/)

¹Paging: reading/writing memory pages from/to disk to reclaim physical memory

²Anonymous memory: memory that is not backed by files or blocks

---

## Enabling swap anyway

- If you don't care that pods are swapping, you can enable swap

- You will need to add the flag `--fail-swap-on=false` to kubelet

  (remember: it won't otherwise start if it detects that swap is enabled)

---

## Pod quality of service

Each pod is assigned a QoS class (visible in `status.qosClass`).

- If limits = requests:

  - as long as the container uses less than the limit, it won't be affected

  - if all containers in a pod have *(limits=requests)*, QoS is considered "Guaranteed"

- If requests &lt; limits:

  - as long as the container uses less than the request, it won't be affected

  - otherwise, it might be killed/evicted if the node gets overloaded

  - if at least one container has *(requests&lt;limits)*, QoS is considered "Burstable"

- If a pod doesn't have any request nor limit, QoS is considered "BestEffort"

---

## Quality of service impact

- When a node is overloaded, BestEffort pods are killed first

- Then, Burstable pods that exceed their requests

- Burstable and Guaranteed pods below their requests are never killed

  (except if their node fails)

- If we only use Guaranteed pods, no pod should ever be killed

  (as long as they stay within their limits)

(Pod QoS is also explained in [this page](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) of the Kubernetes documentation and in [this blog post](https://medium.com/google-cloud/quality-of-service-class-qos-in-kubernetes-bb76a89eb2c6).)

---

## Specifying resources

- Resource requests are expressed at the *container* level

- CPU is expressed in "virtual CPUs"

  (corresponding to the virtual CPUs offered by some cloud providers)

- CPU can be expressed with a decimal value, or even a "milli" suffix

  (so 100m = 0.1)

- Memory and ephemeral disk storage are expressed in bytes

- These can have k, M, G, T, ki, Mi, Gi, Ti suffixes

  (corresponding to 10^3, 10^6, 10^9, 10^12, 2^10, 2^20, 2^30, 2^40)

---

## Specifying resources in practice

This is what the spec of a Pod with resources will look like:

```yaml
containers:
- name: blue
  image: jpetazzo/color
  resources:
    limits:
      cpu: "100m"
      ephemeral-storage: 10M
      memory: "100Mi"
    requests:
      cpu: "10m"
      ephemeral-storage: 10M
      memory: "100Mi"
```

This set of resources makes sure that this service won't be killed (as long as it stays below 100 MB of RAM), but allows its CPU usage to be throttled if necessary.

---

## Default values

- If we specify a limit without a request: 

  the request is set to the limit

- If we specify a request without a limit: 

  there will be no limit

  (which means that the limit will be the size of the node)

- If we don't specify anything:

  the request is zero and the limit is the size of the node

*Unless there are default values defined for our namespace!*

---

## We need to specify resource values

- If we do not set resource values at all:

  - the limit is "the size of the node"

  - the request is zero

- This is generally *not* what we want

  - a container without a limit can use up all the resources of a node

  - if the request is zero, the scheduler can't make a smart placement decision

- This is fine when learning/testing, absolutely not in production!

---

## How should we set resources?

- Option 1: manually, for each container

  - simple, effective, but tedious

- Option 2: automatically, with the [Vertical Pod Autoscaler (VPA)][vpa]

  - relatively simple, very minimal involvement beyond initial setup

  - not compatible with HPAv1, can disrupt long-running workloads (see [limitations][vpa-limitations])

- Option 3: semi-automatically, with tools like [Robusta KRR][robusta]

  - good compromise between manual work and automation

- Option 4: by creating LimitRanges in our Namespaces

  - relatively simple, but "one-size-fits-all" approach might not always work

[robusta]: https://github.com/robusta-dev/krr
[vpa]: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
[vpa-limitations]: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#known-limitations

---

# Defining min, max, and default resources

- We can create LimitRange objects to indicate any combination of:

  - min and/or max resources allowed per pod

  - default resource *limits*

  - default resource *requests*

  - maximal burst ratio (*limit/request*)

- LimitRange objects are namespaced

- They apply to their namespace only

---

## LimitRange example

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: my-very-detailed-limitrange
spec:
  limits:
  - type: Container
    min:
      cpu: "100m"
    max:
      cpu: "2000m"
      memory: "1Gi"
    default:
      cpu: "500m"
      memory: "250Mi"
    defaultRequest:
      cpu: "500m"
```

---

## Example explanation

The YAML on the previous slide shows an example LimitRange object specifying very detailed limits on CPU usage,
and providing defaults on RAM usage.

Note the `type: Container` line: in the future,
it might also be possible to specify limits
per Pod, but it's not [officially documented yet](https://github.com/kubernetes/website/issues/9585).

---

## LimitRange details

- LimitRange restrictions are enforced only when a Pod is created

  (they don't apply retroactively)

- They don't prevent creation of e.g. an invalid Deployment or DaemonSet

  (but the pods will not be created as long as the LimitRange is in effect)

- If there are multiple LimitRange restrictions, they all apply together

  (which means that it's possible to specify conflicting LimitRanges,
  <br/>preventing any Pod from being created)

- If a LimitRange specifies a `max` for a resource but no `default`,
  <br/>that `max` value becomes the `default` limit too

---

## Underutilization

- Remember: when assigning a pod to a node, the scheduler looks at *requests*

  (not at current utilization on the node)

- If pods request resources but don't use them, this can lead to underutilization

  (because the scheduler will consider that the node is full and can't fit new pods)

---

## Viewing a namespace limits and quotas

- `kubectl describe namespace` will display resource limits and quotas

.lab[

- Try it out:
  ```bash
  kubectl describe namespace default
  ```

- View limits and quotas for *all* namespaces:
  ```bash
  kubectl describe namespace
  ```

]

---

## Additional resources

- [A Practical Guide to Setting Kubernetes Requests and Limits](http://blog.kubecost.com/blog/requests-and-limits/)

  - explains what requests and limits are

  - provides guidelines to set requests and limits

  - gives PromQL expressions to compute good values
    <br/>(our app needs to be running for a while)

- [Kube Resource Report](https://codeberg.org/hjacobs/kube-resource-report)

  - generates web reports on resource usage

- [nsinjector](https://github.com/blakelead/nsinjector)

  - controller to automatically populate a Namespace when it is created

???

:EN:- Setting compute resource limits
:EN:- Defining default policies for resource usage
:EN:- Managing cluster allocation and quotas
:EN:- Resource management in practice

:FR:- Allouer et limiter les ressources des conteneurs
:FR:- Définir des ressources par défaut
:FR:- Gérer les quotas de ressources au niveau du cluster
:FR:- Conseils pratiques
