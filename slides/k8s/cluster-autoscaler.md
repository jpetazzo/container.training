# Cluster autoscaler

- When the cluster is full, we need to add more nodes

- This can be done manually:

  - deploy new machines and add them to the cluster

  - if using managed Kubernetes, use some API/CLI/UI

- Or automatically with the cluster autoscaler:

  https://github.com/kubernetes/autoscaler

---

## Use-cases

- Batch job processing

  "once in a while, we need to execute these 1000 jobs in parallel"

  "...but the rest of the time there is almost nothing running on the cluster"

- Dynamic workload

  "a few hours per day or a few days per week, we have a lot of traffic"

  "...but the rest of the time, the load is much lower"

---

## Pay for what you use

- The point of the cloud is to "pay for what you use"

- If you have a fixed number of cloud instances running at all times:

  *you're doing in wrong (except if your load is always the same)*

- If you're not using some kind of autoscaling, you're wasting money

  (except if you like lining the pockets of your cloud provider)

---

## Running the cluster autoscaler

- We must run nodes on a supported infrastructure

- See [here] for a non-exhaustive list of supported providers

- Sometimes, the cluster autoscaler is installed automatically

  (or by setting a flag / checking a box when creating the cluster)

- Sometimes, it requires additional work

  (which is often non-trivial and highly provider-specific)

[here]: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider

---

## Scaling up in theory

IF a Pod is `Pending`,

AND adding a Node would allow this Pod to be scheduled,

THEN add a Node.

---

## Fine print 1

*IF a Pod is `Pending`...*

- First of all, the Pod must exist

- Pod creation might be blocked by e.g. a namespace quota

- In that case, the cluster autoscaler will never trigger

---

## Fine print 2

*IF a Pod is `Pending`...*

- If our Pods do not have resource requests:

  *they will be in the `BestEffort` class*

- Generally, Pods in the `BestEffort` class are schedulable

  - except if they have anti-affinity placement constraints

  - except if all Nodes already run the max number of pods (110 by default)

- Therefore, if we want to leverage cluster autoscaling:

  *our Pods should have resource requests*

---

## Fine print 3

*AND adding a Node would allow this Pod to be scheduled...*

- The autoscaler won't act if:

  - the Pod is too big to fit on a single Node

  - the Pod has impossible placement constraints

- Examples:

  - "run one Pod per datacenter" with 4 pods and 3 datacenters

  - "use this nodeSelector" but no such Node exists

---

## Trying it out

- We're going to check how much capacity is available on the cluster

- Then we will create a basic deployment

- We will add resource requests to that deployment

- Then scale the deployment to exceed the available capacity

- **The following commands require a working cluster autoscaler!**

---

## Checking available resources

.lab[

- Check how much CPU is allocatable on the cluster:
  ```bash
  kubectl get nodes  -o jsonpath={..allocatable.cpu}
  ```

]

- If we see e.g. `2800m 2800m 2800m`, that means:

  3 nodes with 2.8 CPUs allocatable each

- To trigger autoscaling, we will create 7 pods requesting 1 CPU each

  (each node can fit 2 such pods)

---

## Creating our test Deployment

.lab[

- Create the Deployment:
  ```bash
  kubectl create deployment blue --image=jpetazzo/color
  ```

- Add a request for 1 CPU:
  ```bash
    kubectl patch deployment blue --patch='
    spec:
      template:
        spec:
          containers:
          - name: color
            resources:
              requests:
                cpu: 1
    '
  ```
]

---

## Scaling up in practice

- This assumes that we have strictly less than 7 CPUs available

  (adjust the numbers if necessary!)

.lab[

- Scale up the Deployment:
  ```bash
  kubectl scale deployment blue --replicas=7
  ```

- Check that we have a new Pod, and that it's `Pending`:
  ```bash
  kubectl get pods
  ```

]

---

## Cluster autoscaling

- After a few minutes, a new Node should appear

- When that Node becomes `Ready`, the Pod will be assigned to it

- The Pod will then be `Running`

- Reminder: the `AGE` of the Pod indicates when the Pod was *created*

  (it doesn't indicate when the Pod was scheduled or started!)

- To see other state transitions, check the `status.conditions` of the Pod

---

## Scaling down in theory

IF a Node has less than 50% utilization for 10 minutes,

AND all its Pods can be scheduled on other Nodes,

AND all its Pods are *evictable*,

AND the Node doesn't have a "don't scale me down" annotation¹,

THEN drain the Node and shut it down.

.footnote[¹The annotation is: `cluster-autoscaler.kubernetes.io/scale-down-disabled=true`]

---

## When is a Pod "evictable"?

By default, Pods are evictable, except if any of the following is true.

- They have a restrictive Pod Disruption Budget

- They are "standalone" (not controlled by a ReplicaSet/Deployment, StatefulSet, Job...)

- They are in `kube-system` and don't have a Pod Disruption Budget

- They have local storage (that includes `EmptyDir`!)

This can be overridden by setting the annotation:
<br/>
`cluster-autoscaler.kubernetes.io/safe-to-evict`
<br/>(it can be set to `true` or `false`)

---

## Pod Disruption Budget

- Special resource to configure how many Pods can be *disrupted*

  (i.e. shutdown/terminated)

- Applies to Pods matching a given selector

  (typically matching the selector of a Deployment)

- Only applies to *voluntary disruption*

  (e.g. cluster autoscaler draining a node, planned maintenance...)

- Can express `minAvailable` or `maxUnavailable`

- See [documentation] for details and examples

[documentation]: https://kubernetes.io/docs/tasks/run-application/configure-pdb/

---

## Local storage

- If our Pods use local storage, they will prevent scaling down

- If we have e.g. an `EmptyDir` volume for caching/sharing:

  make sure to set the `.../safe-to-evict` annotation to `true`!

- Even if the volume...

  - ...only has a PID file or UNIX socket

  - ...is empty

  - ...is not mounted by any container in the Pod!

---

## Expensive batch jobs

- Careful if we have long-running batch jobs!

  (e.g. jobs that take many hours/days to complete)

- These jobs could get evicted before they complete

  (especially if they use less than 50% of the allocatable resources)

- Make sure to set the `.../safe-to-evict` annotation to `false`!

---

## Node groups

- Easy scenario: all nodes have the same size

- Realistic scenario: we have nodes of different sizes

  - e.g. mix of CPU and GPU nodes

  - e.g. small nodes for control plane, big nodes for batch jobs

  - e.g. leveraging spot capacity

- The cluster autoscaler can handle it!

---

class: extra-details

## Leveraging spot capacity

- AWS, Azure, and Google Cloud are typically more expensive then their competitors

- However, they offer *spot* capacity (spot instances, spot VMs...)

- *Spot* capacity:

  - has a much lower cost (see e.g. AWS [spot instance advisor][awsspot])

  - has a cost that varies continuously depending on regions, instance type...

  - can be preempted at all times

- To be cost-effective, it is strongly recommended to leverage spot capacity

[awsspot]: https://aws.amazon.com/ec2/spot/instance-advisor/

---

## Node groups in practice

- The cluster autoscaler maps nodes to *node groups*

  - this is an internal, provider-dependent mechanism

  - the node group is sometimes visible through a proprietary label or annotation

- Each node group is scaled independently

- The cluster autoscaler uses [expanders] to decide which node group to scale up

  (the default expander is "random", i.e. pick a node group at random!) 

- Of course, only acceptable node groups will be considered

  (i.e. node groups that could accommodate the `Pending` Pods)

[expanders]: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-expanders

---

class: extra-details

## Scaling to zero

- *In general,* a node group needs to have at least one node at all times

  (the cluster autoscaler uses that node to figure out the size, labels, taints... of the group)

- *On some providers,* there are special ways to specify labels and/or taints

  (but if you want to scale to zero, check that the provider supports it!)

---

## Warning

- Autoscaling up is easy

- Autoscaling down is harder

- It might get stuck because Pods are not evictable

- Do at least a dry run to make sure that the cluster scales down correctly!

- Have alerts on cloud spend

- *Especially when using big/expensive nodes (e.g. with GPU!)*

---

## Preferred vs. Required

- Some Kubernetes mechanisms allow to express "soft preferences":

  - affinity (`requiredDuringSchedulingIgnoredDuringExecution` vs `preferredDuringSchedulingIgnoredDuringExecution`)

  - taints (`NoSchedule`/`NoExecute` vs `PreferNoSchedule`)

- Remember that these "soft preferences" can be ignored

  (and given enough time and churn on the cluster, they will!)

---

## Troubleshooting

- The cluster autoscaler publishes its status on a ConfigMap

.lab[

- Check the cluster autoscaler status:
  ```bash
  kubectl describe configmap --namespace kube-system cluster-autoscaler-status
  ```

]

- We can also check the logs of the autoscaler

  (except on managed clusters where it's running internally, not visible to us)

---

## Acknowledgements

Special thanks to [@s0ulshake] for their help with this section!

If you need help to run your data science workloads on Kubernetes,
<br/>they're available for consulting.

(Get in touch with them through https://www.linkedin.com/in/ajbowen/)

[@s0ulshake]: https://twitter.com/s0ulshake
