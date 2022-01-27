# Resource Limits

- We can attach resource indications to our pods

  (or rather: to the *containers* in our pods)

- We can specify *limits* and/or *requests*

- We can specify quantities of CPU and/or memory

---

## CPU vs memory

- CPU is a *compressible resource*

  (it can be preempted immediately without adverse effect)

- Memory is an *incompressible resource*

  (it needs to be swapped out to be reclaimed; and this is costly)

- As a result, exceeding limits will have different consequences for CPU and memory

---

## Exceeding CPU limits

- CPU can be reclaimed instantaneously

  (in fact, it is preempted hundreds of times per second, at each context switch)

- If a container uses too much CPU, it can be throttled

  (it will be scheduled less often)

- The processes in that container will run slower

  (or rather: they will not run faster)

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

For more details, check [this blog post](https://erickhun.com/posts/kubernetes-faster-services-no-cpu-limits/) or these ones ([part 1](https://engineering.indeedblog.com/blog/2019/12/unthrottled-fixing-cpu-limits-in-the-cloud/), [part 2](https://engineering.indeedblog.com/blog/2019/12/cpu-throttling-regression-fix/)).

---

## Exceeding memory limits

- Memory needs to be swapped out before being reclaimed

- "Swapping" means writing memory pages to disk, which is very slow

- On a classic system, a process that swaps can get 1000x slower

  (because disk I/O is 1000x slower than memory I/O)

- Exceeding the memory limit (even by a small amount) can reduce performance *a lot*

- Kubernetes *does not support swap* (more on that later!)

- Exceeding the memory limit will cause the container to be killed

---

## Limits vs requests

- Limits are "hard limits" (they can't be exceeded)

  - a container exceeding its memory limit is killed

  - a container exceeding its CPU limit is throttled

- Requests are used for scheduling purposes

  - a container using *less* than what it requested will never be killed or throttled

  - the scheduler uses the requested sizes to determine placement

  - the resources requested by all pods on a node will never exceed the node size

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

## Where is my swap?

- The semantics of memory and swap limits on Linux cgroups are complex

- With cgroups v1, it's not possible to disable swap for a cgroup

  (the closest option is to [reduce "swappiness"](https://unix.stackexchange.com/questions/77939/turning-off-swapping-for-only-one-process-with-cgroups))

- It is possible with cgroups v2 (see the [kernel docs](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) and the [fbatx docs](https://facebookmicrosites.github.io/cgroup2/docs/memory-controller.html#using-swap))

- Cgroups v2 aren't widely deployed yet

- The architects of Kubernetes wanted to ensure that Guaranteed pods never swap

- The simplest solution was to disable swap entirely

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

  (otherwise, it won't start!)

---

## Specifying resources

- Resource requests are expressed at the *container* level

- CPU is expressed in "virtual CPUs"

  (corresponding to the virtual CPUs offered by some cloud providers)

- CPU can be expressed with a decimal value, or even a "milli" suffix

  (so 100m = 0.1)

- Memory is expressed in bytes

- Memory can be expressed with k, M, G, T, ki, Mi, Gi, Ti suffixes

  (corresponding to 10^3, 10^6, 10^9, 10^12, 2^10, 2^20, 2^30, 2^40)

---

## Specifying resources in practice

This is what the spec of a Pod with resources will look like:

```yaml
containers:
- name: httpenv
  image: jpetazzo/httpenv
  resources:
    limits:
      memory: "100Mi"
      cpu: "100m"
    requests:
      memory: "100Mi"
      cpu: "10m"
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

## We need default resource values

- If we do not set resource values at all:

  - the limit is "the size of the node"

  - the request is zero

- This is generally *not* what we want

  - a container without a limit can use up all the resources of a node

  - if the request is zero, the scheduler can't make a smart placement decision

- To address this, we can set default values for resources

- This is done with a LimitRange object

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

# Namespace quotas

- We can also set quotas per namespace

- Quotas apply to the total usage in a namespace

  (e.g. total CPU limits of all pods in a given namespace)

- Quotas can apply to resource limits and/or requests

  (like the CPU and memory limits that we saw earlier)

- Quotas can also apply to other resources:

  - "extended" resources (like GPUs)

  - storage size

  - number of objects (number of pods, services...)

---

## Creating a quota for a namespace

- Quotas are enforced by creating a ResourceQuota object

- ResourceQuota objects are namespaced, and apply to their namespace only

- We can have multiple ResourceQuota objects in the same namespace

- The most restrictive values are used

---

## Limiting total CPU/memory usage

- The following YAML specifies an upper bound for *limits* and *requests*:
  ```yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: a-little-bit-of-compute
    spec:
      hard:
        requests.cpu: "10"
        requests.memory: 10Gi
        limits.cpu: "20"
        limits.memory: 20Gi
  ```

These quotas will apply to the namespace where the ResourceQuota is created.

---

## Limiting number of objects

- The following YAML specifies how many objects of specific types can be created:
  ```yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: quota-for-objects
    spec:
      hard:
        pods: 100
        services: 10
        secrets: 10
        configmaps: 10
        persistentvolumeclaims: 20
        services.nodeports: 0
        services.loadbalancers: 0
        count/roles.rbac.authorization.k8s.io: 10
  ```

(The `count/` syntax allows limiting arbitrary objects, including CRDs.)

---

## YAML vs CLI

- Quotas can be created with a YAML definition

- ...Or with the `kubectl create quota` command

- Example:
  ```bash
  kubectl create quota my-resource-quota --hard=pods=300,limits.memory=300Gi
  ```

- With both YAML and CLI form, the values are always under the `hard` section

  (there is no `soft` quota)

---

## Viewing current usage

When a ResourceQuota is created, we can see how much of it is used:

```
kubectl describe resourcequota my-resource-quota

Name:                            my-resource-quota
Namespace:                       default
Resource                         Used  Hard
--------                         ----  ----
pods                             12    100
services                         1     5
services.loadbalancers           0     0
services.nodeports               0     0
```

---

## Advanced quotas and PriorityClass

- Pods can have a *priority*

- The priority is a number from 0 to 1000000000

  (or even higher for system-defined priorities)

- High number = high priority = "more important" Pod

- Pods with a higher priority can *preempt* Pods with lower priority

  (= low priority pods will be *evicted* if needed)

- Useful when mixing workloads in resource-constrained environments

---

## Setting the priority of a Pod

- Create a PriorityClass

  (or use an existing one)

- When creating the Pod, set the field `spec.priorityClassName`

- If the field is not set:

  - if there is a PriorityClass with `globalDefault`, it is used

  - otherwise, the default priority will be zero

---

class: extra-details

## PriorityClass and ResourceQuotas

- A ResourceQuota can include a list of *scopes* or a *scope selector*

- In that case, the quota will only apply to the scoped resources

- Example: limit the resources allocated to "high priority" Pods

- In that case, make sure that the quota is created in every Namespace

  (or use *admission configuration* to enforce it)

- See the [resource quotas documentation][quotadocs] for details

[quotadocs]: https://kubernetes.io/docs/concepts/policy/resource-quotas/#resource-quota-per-priorityclass

---

# Limiting resources in practice

- We have at least three mechanisms:

  - requests and limits per Pod

  - LimitRange per namespace

  - ResourceQuota per namespace

- Let's see a simple recommendation to get started with resource limits

---

## Set a LimitRange

- In each namespace, create a LimitRange object

- Set a small default CPU request and CPU limit

  (e.g. "100m")

- Set a default memory request and limit depending on your most common workload

  - for Java, Ruby: start with "1G"

  - for Go, Python, PHP, Node: start with "250M"

- Set upper bounds slightly below your expected node size

  (80-90% of your node size, with at least a 500M memory buffer)

---

## Set a ResourceQuota

- In each namespace, create a ResourceQuota object

- Set generous CPU and memory limits

  (e.g. half the cluster size if the cluster hosts multiple apps)

- Set generous objects limits

  - these limits should not be here to constrain your users

  - they should catch a runaway process creating many resources

  - example: a custom controller creating many pods

---

## Observe, refine, iterate

- Observe the resource usage of your pods

  (we will see how in the next chapter)

- Adjust individual pod limits

- If you see trends: adjust the LimitRange

  (rather than adjusting every individual set of pod limits)

- Observe the resource usage of your namespaces

  (with `kubectl describe resourcequota ...`)

- Rinse and repeat regularly

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

- [Kube Resource Report](https://github.com/hjacobs/kube-resource-report/)

  - generates web reports on resource usage

  - [static demo](https://hjacobs.github.io/kube-resource-report/sample-report/output/index.html)
    |
    [live demo](https://kube-resource-report.demo.j-serv.de/applications.html)

???

:EN:- Setting compute resource limits
:EN:- Defining default policies for resource usage
:EN:- Managing cluster allocation and quotas
:EN:- Resource management in practice

:FR:- Allouer et limiter les ressources des conteneurs
:FR:- Définir des ressources par défaut
:FR:- Gérer les quotas de ressources au niveau du cluster
:FR:- Conseils pratiques
