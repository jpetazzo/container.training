# Disruptions

In a perfect world...

- hardware never fails

- software never has bugs

- ...and never needs to be updated

- ...and uses a predictable amount of resources

- ...and these resources are infinite anyways

- network latency and packet loss are zero

- humans never make mistakes

--

😬

---

## Disruptions

In the real world...

- hardware will fail randomly (without advance notice)

- software has bugs

- ...and we constantly add new features

- ...and will sometimes use more resources than expected

- ...and these resources are limited

- network latency and packet loss are NOT zero

- humans make mistake (shutting down the wrong machine, the wrong app...)

---

## Disruptions

- In Kubernetes, a "disruption" is something that stops the execution of a Pod

- There are **voluntary** and **unvoluntary** disruptions

  - voluntary = directly initiated by humans (including by mistake!)

  - unvoluntary = everything else

- In this section, we're going to see what they are and how to prevent them

  (or at least, mitigate their effects)

---

## Node outage

- Example: hardware failure (server or network), low-level error

  (includes kernel bugs, issues affecting underlying hypervisors or infrastructure...)

- **Unvoluntary** disruption (even if it results from human error!)

- Consequence: all workloads on that node become unresponsive

- Mitigations:

  - scale workloads to at least 2 replicas (or more if quorum is needed)

  - add anti-affinity scheduling constraints (to avoid having all pods on the same node)

---

## Node outage play-by-play

- Node goes down (or disconnected from network)

- Its lease (in Namespace `kube-node-lease`) doesn't get renewed

- Controller manager detects that and mark the node as "unreachable"

  (this adds both a `NoSchedule` and `NoExecute` taints to the node)

- Eventually, the `NoExecute` taint will evict these pods

- This will trigger creation of replacement pods by owner controllers

  (except for pods with a stable network identity, e.g. in a Stateful Set!)

---

## Node outage notes

- By default, pods will tolerate the `unreachable:NoExecute` taint for 5 minutes

  (toleration automatically added by Admission controller `DefaultTolerationSeconds`)

- Pods of a Stateful Set don't recover automatically:

  - as long as the Pod exists, a replacement Pod can't be created

  - the Pod will exist as long as its Node exists

  - deleting the Node (manually or automatically) will recover the Pod

---

## Memory/disk pressure

- Example: available memory on a node goes below a specific threshold

  (because a pod is using too much memory and no limit was set)

- **Unvoluntary** disruption

- Consequence: kubelet starts to *evict* some pods

- Mitigations:

  - set *resource limits* on containers to prevent them from using too much resources

  - set *resource requests* on containers to make sure they don't get evicted
    <br/>
    (as long as they use less than what they requested)

  - make sure that apps don't use more resources than what they've requested

---

## Memory/disk pressure play-by-play

- Memory leak in an application container, slowly causing very high memory usage

- Overall free memory on the node goes below the *soft* or the *hard* threshold

  (default hard threshold = 100Mi; default soft threshold = none)

- When reaching the *soft* threshold:

  - kubelet waits until the "eviction soft grace period" expires

  - then (if resource usage is still above the threshold) it gracefully evicts pods

- When reaching the *hard* threshold:

  - kubelet immediately and forcefully evicts pods

---

## Which pods are evicted?

- Kubelet only considers pods that are using *more* than what they requested

  (and only for the resource that is under pressure, e.g. RAM or disk usage)

- First, it sorts pods by *priority¹* (as set with the `priorityClassName` in the pod spec)

- Then, by how much their resource usage exceeds their request

  (again, for the resource that is under pressure)

- It evicts pods until enough resources have been freed up

---

## Soft (graceful) vs hard (forceful) eviction

- Soft eviction = graceful shutdown of the pod

  (honor's the pod `terminationGracePeriodSeconds` timeout)

- Hard eviction = immediate shutdown of the pod

  (kills all containers immediately)

---

## Memory/disk pressure notes

- If resource usage increases *very fast*, kubelet might not catch it fast enough

- For memory: this will trigger the kernel out-of-memory killer

  - containers killed by OOM are automatically restarted (no eviction)

  - eviction might happen at a later point though (if memory usage stays high)

- For disk: there is no "out-of-disk" killer, but writes will fail

  - the `write` system call fails with `errno = ENOSPC` / `No space left on device`

  - eviction typically happens shortly after (when kubelet catches up)

---

## Memory/disk pressure delays

- By default, no soft threshold is defined

- Defining it requires setting both the threshold and the grace period

- Grace periods can be different for the different types of resources

- When a node is under pressure, kubelet places a `NoSchedule` taint

  (to avoid adding more pods while the pod is under pressure)

- Once the node is no longer under pressure, kubelet clears the taint

  (after waiting an extra timeout, `evictionPressureTransitionPeriod`, 5 min by default)

---

## Accidental deletion

- Example: developer deletes the wrong Deployment, the wrong Namespace...

- **Voluntary** disruption

  (from Kubernetes' perspective!)

- Consequence: application is down

- Mitigations:

  - only deploy to production systems through e.g. gitops workflows

  - enforce peer review of changes

  - only give users limited (e.g. read-only) access to production systems

  - use canary deployments (might not catch all mistakes though!)

---

## Bad code deployment

- Example: critical bug introduced, application crashes immediately or is non-functional

- **Voluntary** disruption

  (again, from Kubernetes' perspective!)

- Consequence: application is down

- Mitigations:

  - readiness probes can mitigate immediate crashes
    <br/>
    (rolling update continues only when enough pods are ready)

  - delayed crashes will require a rollback
    <br/>
    (manual intervention, or automated by a canary system)

---

## Node shutdown

- Example: scaling down a cluster to save money

- **Voluntary** disruption

- Consequence:

  - all workloads running on that node are terminated

  - this might disrupt workloads that have too many replicas on that node

  - or workloads that should not be interrupted at all

- Mitigations:

  - terminate workloads one at a time, coordinating with users

--

🤔

---

## Node shutdown

- Example: scaling down a cluster to save money

- **Voluntary** disruption

- Consequence:

  - all workloads running on that node are terminated

  - this might disrupt workloads that have too many replicas on that node

  - or workloads that should not be interrupted at all

- Mitigations:

  - ~~terminate workloads one at a time, coordinating with users~~

  - use Pod Disruption Budgets

---

## Pod Disruption Budgets

- A PDB is a kind of *contract* between:

  - "admins" = folks maintaining the cluster (e.g. adding/removing/updating nodes)

  - "users" = folks deploying apps and workloads on the cluster

- A PDB expresses something like:

  *in that particular set of pods, do not "disrupt" more than X at a time*

- Examples:

  - in that set of frontend pods, do not disrupt more than 1 at a time

  - in that set of worker pods, always have at least 10 ready
    <br/>
    (do not disrupt them if it would bring down the number of ready pods below 10)

---

## PDB - user side

- Cluster users create a PDB with a manifest like this one:

```yaml
@@INCLUDE[k8s/pod-disruption-budget.yaml]
```

- The PDB must indicate either `minAvailable` or `maxUnavailable`

---

## Rounding logic

- Percentages are rounded **up**

- When specifying `maxUnavailble` as a percentage, this can result in a higher perecentage

  (e.g. `maxUnavailable: 50%` with 3 pods can result in 2 pods being unavailable!)

---

## Unmanaged pods

- Specifying `minAvailable: X` works all the time

- Specifying `minAvailable: X%` or `maxUnavaiable` requires *managed pods*

  (pods that belong to a controller, e.g. Replica Set, Stateful Set...)

- This is because the PDB controller needs to know the total number of pods

  (given by the `replicas` field, not merely by counting pod objects)

- The PDB controller will try to resolve the controller using the pod selector

- If that fails, the PDB controller will emit warning events

  (visible with `kubectl describe pdb ...`)

---

## Zero

- `maxUnavailable: 0` means "do not disrupt my pods"

- Same thing if `minAvailable` is greater than or equal to the number of pods

- In that case, cluster admins are supposed to get in touch with cluster users

- This will prevent fully automated operation

  (and some cluster admins automated systems might not honor that request)

---

## PDB - admin side

- As a cluster admin, we need to follow certain rules

- Only shut down (or restart) a node when no pods are running on that node

  (except system pods belonging to Daemon Sets)

- To remove pods running on a node, we should use the *eviction API*

  (which will check PDB constraints and honor them)

- To prevent new pods from being scheduled on a node, we can use a *taint*

- These operations are streamlined by `kubectl drain`, which will:

  - *cordon* the node (add a `NoSchedule` taint)

  - invoke the *eviction API* to remove pods while respecting their PDBs

---

## Theory vs practice

- `kubectl drain` won't evict pods using `emptyDir` volumes

  (unless the `--delete-emptydir-data` flag is passed as well)

- Make sure that `emptyDir` volumes don't hold anything important

  (they shouldn't, but... who knows!)

- Kubernetes lacks a standard way for users to express:

  *this `emptyDir` volume can/cannot be safely deleted*

- If a PDB forbids an eviction, this requires manual coordination

---

class: extra-details

## Unhealthy pod eviction policy

- By default, unhealthy pods can only be evicted if PDB allows it

  (unhealthy = running, but not ready)

- In many cases, unhealthy pods aren't healthy anyway, and can be removed

- This behavior is enabled by setting the appropriate field in the PDB manifest:
 
```yaml
spec:
  unhealthyPodEvictionPolicy: AlwaysAllow
```

---

## Node upgrade

- Example: upgrading kubelet or the Linux kernel on a node

- **Voluntary** disruption

- Consequence:

  - all workloads running on that node are temporarily interrupted, and restarted

  - this might disrupt these workloads

- Mitigations:

  - migrate workloads off the done first (as if we were shutting it down)

---

## Node upgrade notes

- Is it necessary to drain a node before doing an upgrade?

- From [the documentation][node-upgrade-docs]:

  *Draining nodes before upgrading kubelet ensures that pods are re-admitted and containers are re-created, which may be necessary to resolve some security issues or other important bugs.*

- It's *probably* safe to upgrade in-place for:

  - kernel upgrades

  - kubelet patch-level upgrades (1.X.Y → 1.X.Z)

- It's *probably* better to drain the node for minor revisions kubelet upgrades (1.X → 1.Y)

- In doubt, test extensively in staging environments!

[node-upgrade-docs]: https://kubernetes.io/docs/tasks/administer-cluster/cluster-upgrade/#manual-deployments

---

## Manual rescheduling

- Example: moving workloads around to accommodate noisy neighbors or other issues

  (e.g. pod X is doing a lot of disk I/O and this is starving other pods)

- **Voluntary** disruption

- Consequence:

  - the moved workloads are temporarily interrupted

- Mitigations:

  - define an appropriate number of replicas, declare PDBs

  - use the [eviction API][eviction-API] to move workloads

[eviction-API]: https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/

???

:EN:- Voluntary and unvoluntary disruptions
:EN:- Pod Disruption Budgets
:FR:- "Disruptions" volontaires et involontaires
:FR:- Pod Disruption Budgets
