# Orchestration, an overview

In this chapter, we will:

* Explain what is orchestration and why we would need it.

* Present (from a high-level perspective) some orchestrators.

* Show one orchestrator (Kubernetes) in action.

---

class: pic

## What's orchestration?

![Joana Carneiro (orchestra conductor)](images/conductor.jpg)

---

## What's orchestration?

According to Wikipedia:

*Orchestration describes the __automated__ arrangement,
coordination, and management of complex computer systems,
middleware, and services.*

--

*[...] orchestration is often discussed in the context of 
__service-oriented architecture__, __virtualization__, provisioning, 
Converged Infrastructure and __dynamic datacenter__ topics.*

--

What does that really mean?

---

## Example 1: dynamic cloud instances

--

- Q: do we always use 100% of our servers?

--

- A: obviously not!

.center[![Daily variations of traffic](images/traffic-graph.png)]

---

## Example 1: dynamic cloud instances

- Every night, scale down
  
  (by shutting down extraneous replicated instances)

- Every morning, scale up
  
  (by deploying new copies)

- "Pay for what you use"
  
  (i.e. save big $$$ here)

---

## Example 1: dynamic cloud instances

How do we implement this?

- Crontab
  
- Autoscaling (save even bigger $$$)

That's *relatively* easy.

Now, how are things for our IAAS provider?

---

## Example 2: dynamic datacenter

- Q: what's the #1 cost in a datacenter?

--

- A: electricity!

--

- Q: what uses electricity?

--

- A: servers, obviously

- A: ... and associated cooling

--

- Q: do we always use 100% of our servers?

--

- A: obviously not!

---

## Example 2: dynamic datacenter

- If only we could turn off unused servers during the night...

- Problem: we can only turn off a server if it's totally empty!
  
  (i.e. all VMs on it are stopped/moved)

- Solution: *migrate* VMs and shutdown empty servers
  
  (e.g. combine two hypervisors with 40% load into 80%+0%,
  <br/>and shutdown the one at 0%)

---

## Example 2: dynamic datacenter

How do we implement this?

- Shutdown empty hosts (but keep some spare capacity)

- Start hosts again when capacity gets low

- Ability to "live migrate" VMs
  
  (Xen already did this 10+ years ago)

- Rebalance VMs on a regular basis
  
  - what if a VM is stopped while we move it?
  - should we allow provisioning on hosts involved in a migration?

*Scheduling* becomes more complex.

---

## What is scheduling?

According to Wikipedia (again):

*In computing, scheduling is the method by which threads, 
processes or data flows are given access to system resources.*

The scheduler is concerned mainly with:

- throughput (total amount or work done per time unit);
- turnaround time (between submission and completion);
- response time (between submission and start);
- waiting time (between job readiness and execution);
- fairness (appropriate times according to priorities).

In practice, these goals often conflict.

**"Scheduling" = decide which resources to use.**

---

## Exercise 1

- You have:

  - 5 hypervisors (physical machines)

- Each server has:

  - 16 GB RAM, 8 cores, 1 TB disk

- Each week, your team asks:

  - one VM with X RAM, Y CPU, Z disk

Scheduling = deciding which hypervisor to use for each VM.

Difficulty: easy!

---

<!-- Warning, two almost identical slides (for img effect) -->

## Exercise 2

- You have:

  - 1000+ hypervisors (and counting!)

- Each server has different resources:

  - 8-500 GB of RAM, 4-64 cores, 1-100 TB disk

- Multiple times a day, a different team asks for:

  - up to 50 VMs with different characteristics

Scheduling = deciding which hypervisor to use for each VM.

Difficulty: ???

---

<!-- Warning, two almost identical slides (for img effect) -->

## Exercise 2

- You have:

  - 1000+ hypervisors (and counting!)

- Each server has different resources:

  - 8-500 GB of RAM, 4-64 cores, 1-100 TB disk

- Multiple times a day, a different team asks for:

  - up to 50 VMs with different characteristics

Scheduling = deciding which hypervisor to use for each VM.

![Troll face](images/trollface.png)

---

## Exercise 3

- You have machines (physical and/or virtual)

- You have containers

- You are trying to put the containers on the machines

- Sounds familiar?

---

## Scheduling with one resource

.center[![Not-so-good bin packing](images/binpacking-1d-1.gif)]

Can we do better?

---

## Scheduling with one resource

.center[![Better bin packing](images/binpacking-1d-2.gif)]

Yup!

---

## Scheduling with two resources

.center[![2D bin packing](images/binpacking-2d.gif)]

---

## Scheduling with three resources

.center[![3D bin packing](images/binpacking-3d.gif)]

---

## You need to be good at this

.center[![Tangram](images/tangram.gif)]

---

## But also, you must be quick!

.center[![Tetris](images/tetris-1.png)]

---

## And be web scale!

.center[![Big tetris](images/tetris-2.gif)]

---

## And think outside (?) of the box!

.center[![3D tetris](images/tetris-3.png)]

---

## Good luck!

.center[![FUUUUUU face](images/fu-face.jpg)]

---

## TL,DR

* Scheduling with multiple resources (dimensions) is hard.

* Don't expect to solve the problem with a Tiny Shell Script.

* There are literally tons of research papers written on this.

---

## But our orchestrator also needs to manage ...

* Network connectivity (or filtering) between containers.

* Load balancing (external and internal).

* Failure recovery (if a node or a whole datacenter fails).

* Rolling out new versions of our applications.

  (Canary deployments, blue/green deployments...)


---

## Some orchestrators

We are going to present briefly a few orchestrators.

There is no "absolute best" orchestrator.

It depends on:

- your applications,

- your requirements,

- your pre-existing skills...

---

## Nomad

- Open Source project by Hashicorp.

- Arbitrary scheduler (not just for containers).

- Great if you want to schedule mixed workloads.

  (VMs, containers, processes...)

- Less integration with the rest of the container ecosystem.

---

## Mesos

- Open Source project in the Apache Foundation.

- Arbitrary scheduler (not just for containers).

- Two-level scheduler.

- Top-level scheduler acts as a resource broker.

- Second-level schedulers (aka "frameworks") obtain resources from top-level.

- Frameworks implement various strategies.

  (Marathon = long running processes; Chronos = run at intervals; ...)

- Commercial offering through DC/OS my Mesosphere.

---

## Rancher

- Rancher 1 offered a simple interface for Docker hosts.

- Rancher 2 is a complete management platform for Docker and Kubernetes.

- Technically not an orchestrator, but it's a popular option.

---

## Swarm

- Tightly integrated with the Docker Engine.

- Extremely simple to deploy and setup, even in multi-manager (HA) mode.

- Secure by default.

- Strongly opinionated:

  - smaller set of features,

  - easier to operate.

---

## Kubernetes

- Open Source project initiated by Google.

- Contributions from many other actors.

- *De facto* standard for container orchestration.

- Many deployment options; some of them very complex.

- Reputation: steep learning curve.

- Reality:

  - true, if we try to understand *everything*;

  - false, if we focus on what matters.

