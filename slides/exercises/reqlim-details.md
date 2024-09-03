# Exercise — Requests and Limits

By default, if we don't specify *resource requests*,
our workloads will run in `BestEffort` quality of service.

`BestEffort` is very bad for production workloads,
because the scheduler has no idea of the actual resource
requirements of our apps, and won't be able to make
smart decisions about workload placement.

As a result, when the cluster gets overloaded, 
containers will be killed, pods will be evicted,
and service disruptions will happen.

Let's solve this!

---

## Check current state

- Check *allocations*

  (i.e. which pods have requests and limits for CPU and memory)

- Then check *utilization*

  (i.e. actual resource usage)

- Possible tools: `kubectl`, plugins like `view-allocations`, Prometheus...

---

## Follow best practices

- We want to make sure that *all* workloads have requests

  (and perhaps limits, too!)

- Depending on the workload:

  - edit its YAML manifest

  - adjust its Helm values

  - add LimitRange in its Namespace

- Then check again to confirm that the job has been done properly!

---

## Be future-proof!

- We want to make sure that *future* workloads will have requests, too

- How can that be implemented?
