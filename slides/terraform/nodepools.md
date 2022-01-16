## Saving (lots of) money

- Our load (number and size of pods) is probably variable

- We need *cluster autoscaling*

  (add/remove nodes as we need them, pay only for what we use)

- We might need nodes of different sizes

  (or with specialized hardware: local fast disks, GPUs...)

- If possible, we should leverage "spot" or "preemptible" capacity

  (VMs that are significantly cheaper but can be terminated on short notice)

---

## Node pools

- We will have multiple *node pools*

- A node pool is a set of nodes running in a single zone

- The nodes usually¹ have the same size

- They have the same "preemptability"

  (i.e. a node pool is either "on-demand" or "preemptible")

- The Kubernetes cluster autoscaler is aware of the node pools

- When it scales up the cluster, it decides which pool(s) to scale up

.footnote[¹On AWS EKS, node pools map to ASGs, which can have mixed instance types.]

---

## Example: big batch

- Every few days, we want to process a batch made of thousands of jobs

- Each job requires lots of RAM (10+ GB) and takes hours to complete

- We want to process the batch as fast as possible

- We don't want to pay for nodes when we don't use them

- Solution:

  - one node group with tiny nodes for basic cluster services

  - one node group with huge nodes for batch processing

  - that second node group "scales to zero"

---

## Gotchas

- Make sure that long-running pods *never* run on big nodes

  (use *taints* and *tolerations*)

- Keep an eye on preemptions

  (especially on very long jobs taking 10+ hours or even days)

---

## Example: mixed load

- Running a majority of stateless apps

- We want to reduce overall cost (target: 25-50%)

- We can accept occasional small disruptions (performance degradations)

- Solution:

  - one node group with "on demand" nodes

  - one node group with "spot" / "preemptible" nodes

  - pin stateful apps to "on demand" nodes

  - *try* to balance stateless apps between the two pools

---

## Gotchas

- We can tell the Kubernetes scheduler to *prefer* balancing across pools

- We don't have a way to *require* it

- What should be done anyway if it's not possible to balance?
 
  (e.g. if spot capacity is unavailable)

- In practice, preemption can be very rare

- This means big savings, but we should have a "plan B" just in case

  (perhaps think about which services can tolerate a rare outage)

---

## In practice

- Most managed Kubernetes providers give us ways to create multiple node pools

- Sometimes the pools are declared as *blocks* within the cluster resources

  - pros: simpler, sometimes faster to provision

  - cons: changing the pool configuration generally forces re-creation of the cluster

- Sometimes the pools are declared as independent resources

  - pros: can add/remove/change pools without destroying the cluster

  - cons: more complex

- Most providers recommend to declare the pools independently
