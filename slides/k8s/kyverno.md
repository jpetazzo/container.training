# Policy Management with Kyverno

- The Kubernetes permission management system is very flexible ...

- ... But it can't express *everything!*

- Examples:

  - forbid using `:latest` image tag

  - enforce that each Deployment, Service, etc. has an `owner` label
    <br/>(except in e.g. `kube-system`)

  - enforce that each container has at least a `readinessProbe` healthcheck

- How can we address that, and express these more complex *policies?*

---

## Admission control

- The Kubernetes API server provides a generic mechanism called *admission control*

- Admission controllers will examine each write request, and can:

  - approve/deny it (for *validating* admission controllers)

  - additionally *update* the object (for *mutating* admission controllers)

- These admission controllers can be:

  - plug-ins built into the Kubernetes API server
    <br/>(selectively enabled/disabled by e.g. command-line flags)

  - webhooks registered dynamically with the Kubernetes API server

---

## What's Kyverno?

- Policy management solution for Kubernetes

- Open source (https://github.com/kyverno/kyverno/)

- Compatible with all clusters

  (doesn't require to reconfigure the control plane, enable feature gates...)

- We don't endorse / support it in a particular way, but we think it's cool

- It's not the only solution!

  (see e.g. [Open Policy Agent](https://www.openpolicyagent.org/docs/v0.12.2/kubernetes-admission-control/))

---

## What can Kyverno do?

- *Validate* resource manifests

  (accept/deny depending on whether they conform to our policies)

- *Mutate* resources when they get created or updated

  (to add/remove/change fields on the fly)

- *Generate* additional resources when a resource gets created

  (e.g. when namespace is created, automatically add quotas and limits)

- *Audit* existing resources

  (warn about resources that violate certain policies)

---

## How does it do it?

- Kyverno is implemented as a *controller* or *operator*

- It typically runs as a Deployment on our cluster

- Policies are defined as *custom resource definitions*

- They are implemented with a set of *dynamic admission control webhooks*

--

🤔

--

- Let's unpack that!

---

## Custom resource definitions

- When we install Kyverno, it will register new resource types:

  - Policy and ClusterPolicy (per-namespace and cluster-scope policies)

  - PolicyViolation and ClusterPolicyViolation (used in audit mode)

  - GenerateRequest (used internally when generating resources asynchronously)

- We will be able to do e.g. `kubectl get policyviolations --all-namespaces`

  (to see policy violations across all namespaces)

- Policies will be defined in YAML and registered/updated with e.g. `kubectl apply`

---

## Dynamic admission control webhooks

- When we install Kyverno, it will register a few webhooks for its use

  (by creating ValidatingWebhookConfiguration and MutatingWebhookConfiguration resources)

- All subsequent resource modifications are submitted to these webhooks

  (creations, updates, deletions)

---

## Controller

- When we install Kyverno, it creates a Deployment (and therefore, a Pod)

- That Pod runs the server used by the webhooks

- It also runs a controller that will:

  - run optional checks in the background (and generate PolicyViolation objects)

  - process GenerateRequest objects asynchronously

---

## Kyverno in action

- We're going to install Kyverno on our cluster

- Then, we will use it to implement a few policies

---

class: extra-details

## Kyverno versions

- We're going to use version 1.2

- Version 1.3.0-rc came out in November 2020

- It introduces a few changes

  (e.g. PolicyViolations are now PolicyReports)

- Expect this to change in the near future!

---

## Installing Kyverno

- Kyverno can be installed with a (big) YAML manifest

- ... or with Helm charts (which allows to customize a few things)

.exercise[

- Install Kyverno:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno\
  /v1.2.1/definitions/release/install.yaml
  ```

]

---

## Kyverno policies in a nutshell

- Which resources does it *select?*

  - can specify resources to *match* and/or *exclude*

  - can specify *kinds* and/or *selector* and/or users/roles doing the action

- Which operation should be done?

  - validate, mutate, or generate

- For validation, whether it should *enforce* or *audit* failures

- Operation details (what exactly to validate, mutate, or generate)

---

## Immutable primary colors, take 1

- Our pods can have an optional `color` label

- If the label exists, it *must* be `red`, `green`, or `blue`

- One possible approach:

  - *match* all pods that have a `color` label that is not `red`, `green`, or `blue`

  - *deny* these pods

- We could also *match* all pods, then *deny* with a condition

---

## Testing without the policy

- First, let's create a pod with an "invalid" label

  (while we still can!)

- We will use this later

.exercise[

- Create a pod:
  ```bash
  kubectl run test-color-0 --image=nginx
  ```

- Apply a color label:
  ```bash
  kubectl label pod test-color-0 color=purple
  ```

]

---

## Our first Kyverno policy

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-1.yaml]
```
]

---

## Load and try the policy

.exercise[

- Load the policy:
  ```bash
  kubectl apply -f ~/container.training/k8s/kyverno-pod-color-1.yaml
  ```

- Create a pod:
  ```bash
  kubectl run test-color-1 --image=nginx
  ```

- Try to apply a few color labels:
  ```bash
  kubectl label pod test-color-1 color=purple
  kubectl label pod test-color-1 color=red
  kubectl label pod test-color-1 color-
  ```

]

---

## Immutable primary colors, take 2

- New rule: once a `color` label has been added, it cannot be changed

  (i.e. if `color=red`, we can't change it to `color=blue`)

- Our approach:

  - *match* all pods

  - *deny* these pods if their `color` label has changed

- "Old" and "new" versions of the pod can be referenced through

  `{{ request.oldObject }}` and `{{ request.object }}`

- Our label is available through `{{ request.object.metadata.labels.color }}`

- Again, other approaches are possible!

---

## Our second Kyverno policy

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-2.yaml]
```
]

---

## Load and try the policy

.exercise[

- Load the policy:
  ```bash
  kubectl apply -f ~/container.training/k8s/kyverno-pod-color-2.yaml
  ```

- Create a pod:
  ```bash
  kubectl run test-color-2 --image=nginx
  ```

- Try to apply a few color labels:
  ```bash
  kubectl label test-color-2 color=purple
  kubectl label test-color-2 color=red
  kubectl label test-color-2 color=blue --overwrite
  ```

]

---

## `background`

- What is this `background: false` option, and why do we need it?

--

- Admission controllers are only invoked when we change an object

- Existing objects are not affected

  (e.g. if we have a pod with `color=pink` *before* installing our policy)

- Kyvero can also run checks in the background, and report violations

  (we'll see later how they are reported)

- `background: false` disables that

--

- Alright, but ... *why* do we need it?

---

## Accessing `AdmissionRequest` context

- In this specific policy, we want to prevent an *update*

  (as opposed to a mere *create* operation)

- We want to compare the *old* and *new* version

  (to check if a specific label was removed)

- The `AdmissionRequest` object has `object` and `oldObject` fields

  (the `AdmissionRequest` object is the thing that gets submitted to the webhook)

- Kyverno lets us access the `AdmissionRequest` object

  (and in particular, `{{ request.object }}` and `{{ request.oldObject }}`)

--

- Alright, but ... what's the link with `background: false`?

---

## `{{ request }}`

- The `{{ request }}` context is only available when there is an `AdmissionRequest`

- When a resource is "at rest", there is no `{{ request }}` (and no old/new)

- Therefore, a policy that uses `{{ request }}` cannot validate existing objects

  (it can only be used when an object is actually created/updated/deleted)

---

## Immutable primary colors, take 3

- New rule: once a `color` label has been added, it cannot be removed

- Our approach:

  - *match* all pods that *do not* have a `color` label

  - *deny* these pods if they had a `color` label before

  - "before" can be referenced through `{{ request.oldObject }}`

- Again, other approaches are possible!

---

## Our third Kyverno policy

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-3.yaml]
```
]

---

## Load and try the policy

.exercise[

- Load the policy:
  ```bash
  kubectl apply -f ~/container.training/k8s/kyverno-pod-color-3.yaml
  ```

- Create a pod:
  ```bash
  kubectl run test-color-3 --image=nginx
  ```

- Try to apply a few color labels:
  ```bash
  kubectl label test-color-3 color=purple
  kubectl label test-color-3 color=red
  kubectl label test-color-3 color-
  ```

]

---

## Background checks

- What about the `test-color-0` pod that we create initially?

  (remember: we did set `color=purple`)

- Kyverno generated a ClusterPolicyViolation to indicate it

.exercise[

- Check that the pod still an "invalid" color:
  ```bash
  kubectl get pods -L color
  ```

- List ClusterPolicyViolations:
  ```bash
  kubectl get clusterpolicyviolations
  kubectl get cpolv
  ```

]

---

## Generating objects

- When we create a Namespace, we also want to automatically create:

  - a LimitRange (to set default CPU and RAM requests and limits)

  - a ResourceQuota (to limit the resources used by the namespace)

  - a NetworkPolicy (to isolate the namespace)

- We can do that with a Kyverno policy with a *generate* action

  (it is mutually exclusive with the *validate* action)

---

## Overview

- The *generate* action must specify:

  - the `kind` of resource to generate

  - the `name` of the resource to generate

  - its `namespace`, when applicable

  - *either* a `data` structure, to be used to populate the resource

  - *or* a `clone` reference, to copy an existing resource

Note: the `apiVersion` field appears to be optional.

---

## In practice

- We will use the policy @@LINK[k8s/kyverno-namespace-setup.yaml]

- We need to generate 3 resources, so we have 3 rules in the policy

- Excerpt:
  ```yaml
      generate: 
      kind: LimitRange
      name: default-limitrange
      namespace: "{{request.object.metadata.name}}" 
      data:
        spec:
          limits:
  ```

- Note that we have to specify the `namespace`

  (and we infer it from the name of the resource being created, i.e. the Namespace)

---

## Lifecycle

- After generated objects have been created, we can change them

  (Kyverno won't update them)

- Except if we use `clone` together with the `synchronize` flag

  (in that case, Kyverno will watch the cloned resource)

- This is convenient for e.g. ConfigMaps shared between Namespaces

- Objects are generated only at *creation* (not when updating an old object)

---

## Asynchronous creation

- Kyverno creates resources asynchronously

  (by creating a GenerateRequest resource first)

- This is useful when the resource cannot be created

  (because of permissions or dependency issues)

- Kyverno will periodically loop through the pending GenerateRequests

- Once the ressource is created, the GenerateRequest is marked as Completed

---

## Footprint

- 5 CRDs: 4 user-facing, 1 internal (GenerateRequest)

- 5 webhooks

- 1 Service, 1 Deployment, 1 ConfigMap

- Internal resources (GenerateRequest) "parked" in a Namespace

- Kyverno packs a lot of features in a small footprint

---

## Strengths

- Kyverno is very easy to install

  (it's harder to get easier than one `kubectl apply -f`)

- The setup of the webhooks is fully automated

  (including certificate generation)

- It offers both namespaced and cluster-scope policies

  (same thing for the policy violations)

- The policy language leverages existing constructs

  (e.g. `matchExpressions`)

---

## Caveats

- By default, the webhook failure policy is `Ignore`

  (meaning that there is a potential to evade policies if we can DOS the webhook)

- Advanced policies (with conditionals) have unique, exotic syntax:
  ```yaml
      spec:
	    =(volumes):
	      =(hostPath):
	        path: "!/var/run/docker.sock"
  ```

- The `{{ request }}` context is powerful, but difficult to validate

  (Kyverno can't know ahead of time how it will be populated)

- Policy validation is difficult

---

class: extra-details

## Pods created by controllers

- When e.g. a ReplicaSet or DaemonSet creates a pod, it "owns" it

  (the ReplicaSet or DaemonSet is listed in the Pod's `.metadata.ownerReferences`)

- Kyverno treats these Pods differently

- If my understanding of the code is correct (big *if*):

  - it skips validation for "owned" Pods

  - instead, it validates their controllers

  - this way, Kyverno can report errors on the controller instead of the pod

- This can be a bit confusing when testing policies on such pods!

???

:EN:- Policy Management with Kyverno
:FR:- Gestion de *policies* avec Kyverno
