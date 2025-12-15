# Taints and tolerations

- Kubernetes gives us many mechanisms to influence where Pods should run:

  taints and tolerations; node selectors; affinity; resource requests...

- Taints and tolerations are used to:

  - reserve a Node for special workloads (e.g. control plane, GPU, security...)

  - temporarily block a node (e.g. for maintenance, troubleshooting...)

  - evacuate a node that exhibits an issue

- In fact, the default failover mechanism on Kubernetes relies on "taint-based evictions"

- Let's dive into all that!

---

## Taints and tolerations

- A *taint* is an attribute added to a node

- It prevents pods from running on the node

- ... Unless they have a matching *toleration*

- Example: when deploying with `kubeadm`...

  - a taint is placed on the node dedicated to the control plane

  - the pods running the control plane have a matching toleration

---

## Checking taints on our nodes

Here are a few ways to view taints on our nodes:

```bash
kubectl describe nodes | grep ^Taints

kubectl get nodes -o custom-columns=NAME:metadata.name,TAINTS:spec.taints

kubectl get nodes -o json | jq '.items[] | [.metadata.name, .spec.taints]'
```

It's possible that your nodes have no taints at all.

(It's not an error or a problem.)

---

## Taint structure

- As shown by `kubectl explain node.spec.taints`, a taint has:

  - an `effect` (mandatory)

  - a `key` (mandatory)

  - a `value` (optional)

- Let's see what they mean!

---

## Taint `key` (mandatory)

- The `key` is an arbitrary string to identify a particular taint

- It can be interpreted in multiple ways, for instance:

  - a reservation for a special set of pods
    <br/>
    (e.g. "this node is reserved for the control plane")

  - an (hopefully temporary) error condition on the node
    <br/>
    (e.g. "this node disk is full, do not start new pods there!")

  - a temporary "hold" on the node
    <br/>
    (e.g. "we're going to do a maintenance operation on that node")

---

## Taint `effect` (mandatory)

- `NoSchedule` = do not place new Pods on that node

  - existing Pods are unaffected
  
- `PreferNoSchedule` = try to not place new Pods on that node

  - place Pods on other nodes if possible

  - use case: cluster autoscaler trying to deprovision a node

- `NoExecute` = stop execution of Pods on that node

  - existing Pods are terminated (technically: evicted)

  - use case: node is in a critical state and workloads should be relocated

---

## Taint `value` (optional)

- This is an optional field

- A taint can exist with just a `key`, or `key` + `value`

- Tolerations can match a taint's `key`, or `key` + `value`

  (we're going to explain tolerations in just a minute!)

---

## Checking tolerations on our Pods

Here are a few ways to see tolerations on the Pods in the current Namespace:

```bash
kubectl get pods -o custom-columns=NAME:metadata.name,TOLERATIONS:spec.tolerations

kubectl get pods -o json | 
jq '.items[] | {"pod_name": .metadata.name} + .spec.tolerations[]'
```

This output will likely be very verbose.

Suggestion: try this...

- in a pod with a few "normal" Pods (created by a Deployment)

- in `kube-system`, with a selector to see only CoreDNS Pods

---

## Toleration structure

- As shown by `kubectl explain pod.spec.tolerations`, a toleration has:

  - an `effect`

  - a `key`

  - an `operator`

  - a `value`


  - a `tolerationSeconds`

- All fields are optional, but they can't all be empty

- Let's see what they mean!

---

## Toleration `effect`

- Same meaning as the `effect` for taints

- If it's omitted, it means "tolerate all kinds of taints"

---

## Toleration `key`

- Same meaning as the `key` for taints

  ("tolerate the taints that have that specific `key`")

- Special case: the `key` can be omitted to indicate "match all keys"

- In that case, the `operator` must be `Exists`

  (it's not possible to omit both `key` and `operator`)

---

## Toleration `operator`

- Can be either `Equal` (the default value) or `Exists`

- `Equal` means:

  *match taints with the exact same `key` and `value` as this toleration*

- `Exists` means:

  *match taints with the same `key` as this toleration, but ignore the taints' `value`*

- As seen earlier, it's possible to specify `Exists` with an empty `key`; that means:

  *match taints with any `key` or `value`*

---

## Toleration `value`

- Will match taints with the same `value`

---

## Toleration `tolerationSeconds`

- Applies only to `NoExecute` taints and tolerations

  (the ones that provoke an *eviction*, i.e. termination, of Pods)

- Indicates that a taint will be ignored for the given amount of time

- After that time has passed, the taint will take place

  (and the Pod will be evicted and terminated)

- This is used notably for automated failover using *taint-based evictions*

  (and more generally speaking, to tolerate transient problems)

---

## Taint-based evictions

- Pods¹ automatically receive these two tolerations:

  ```yaml
    - key: node.kubernetes.io/not-ready
      effect: NoExecute
      operator: Exists
      tolerationSeconds: 300
    - key: node.kubernetes.io/unreachable
      effect: NoExecute
      operator: Exists
      tolerationSeconds: 300
  ```

- So, what's the effect of these tolerations? 🤔

.footnote[¹Except Pods created by DaemonSets, or Pods already specifying similar tolerations]

---

## Node `not-ready` or `unreachable`

- Nodes are supposed to check in with the control plane at regular intervals

  (by default, every 20 seconds)

- When a Node fails to report to the control plane:

  *the control plane adds the `node.kubernetes.io/unreachable` taint to that node*

- The taint is tolerated for 300 seconds

  (i.e. for 5 minutes, nothing happens)

- After that delay expires, the taint applies fully

  *Pods are evicted*

  *replacement Pods should be scheduled on healthy Nodes*

---

## Use-cases

- By default, ~5 minutes after a Node becomes unresponsive, its Pods get rescheduled

- That delay can be changed

  (by adding tolerations with the same `key`+`effect`+`operator` combo)

- This means that we can specify:

  - higher delays for Pods that are "expensive" to move
    <br/>
    (e.g. because they hold a lot of state)

  - lower delays for Pods that should failover as quickly as possible

---

## Manipulating taints

- We can add/remove taints with the usual Kubernetes modification commands

  (e.g. `kubectl edit`, `kubectl patch`, `kubectl apply`...)

- There are also 4 `kubectl` commands specifically for taints:

  `kubectl taint node NodeName key=val:effect` (`val` is optional)

  `kubectl untaint` (with the same arguments)

  `kubectl cordon NodeName` / `kubectl uncordon NodeName`
  <br/>
  (adds or remove the taint `node.kubernetes.io/unschedulable:NoSchedule`)

- The command `kubectl drain` will do a `cordon` and then evict Pods on the Node

???

:EN:- Taints and tolerations
:FR:- Les "taints" et "tolerations"
