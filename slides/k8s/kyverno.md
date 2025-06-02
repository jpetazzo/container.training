# Policy Management with Kyverno

- Kyverno is a policy engine for Kubernetes

- It has many use cases, including:

  - validating resources when they are created/edited
    <br/>(blocking or logging violations)

  - preventing some modifications
    <br/>(e.g. restricting modifications to some fields, labels...)

  - modifying resources automatically

  - generating resources automatically

  - clean up resources automatically

---

## Examples (validation)

- [Disallow `:latest` tag](https://kyverno.io/policies/best-practices/disallow-latest-tag/disallow-latest-tag/)

- [Disallow secrets in environment variables](https://kyverno.io/policies/other/disallow-secrets-from-env-vars/disallow-secrets-from-env-vars/)

- [Require that containers drop all capabilities](https://kyverno.io/policies/best-practices/require-drop-all/require-drop-all/)

- [Prevent creation of Deployment, ReplicaSet, etc. without an HPA](https://kyverno.io/policies/other/check-hpa-exists/check-hpa-exists/)

- [Forbid CPU limits](https://kyverno.io/policies/other/forbid-cpu-limits/forbid-cpu-limits/)

- [Check that memory requests are equal to limits](https://kyverno.io/policies/other/memory-requests-equal-limits/memory-requests-equal-limits/)

- [Require containers to have healthchecks](https://kyverno.io/policies/best-practices/require-probes/require-probes/)

---

## Examples (mutation)

- [Automatically add environment variables from a ConfigMap](https://kyverno.io/policies/other/add-env-vars-from-cm/add-env-vars-from-cm/)

- [Add image as an environment variable](https://kyverno.io/policies/other/add-image-as-env-var/add-image-as-env-var/)

- [Add image `LABEL` as an environment variable](https://kyverno.io/policies/other/inject-env-var-from-image-label/inject-env-var-from-image-label/)

- [When creating a Deployment, copy some labels from its Namespace](https://kyverno.io/policies/other/copy-namespace-labels/copy-namespace-labels/)

- [Automatically restart a given Deployment when a given ConfigMap changes](https://kyverno.io/policies/other/restart-deployment-on-secret-change/restart-deployment-on-secret-change/)

---

## Examples (generation)

- [Automatically create a PDB when a Deployment is created](https://kyverno.io/policies/other/create-default-pdb/create-default-pdb/)

- [Create an event when an object is deleted (for auditing purposes)](https://kyverno.io/policies/other/audit-event-on-delete/audit-event-on-delete/)

- [Create an audit event when using `kubectl exec`](https://kyverno.io/policies/other/audit-event-on-exec/audit-event-on-exec/)

- [Automatically create a Secret (e.g. for registry auth) when a Namespace is created](https://kyverno.io/policies/other/sync-secrets/sync-secrets/)

---

## Examples (advanced validation)

- [Only allow root user in images coming from a trusted registry](https://kyverno.io/policies/other/only-trustworthy-registries-set-root/only-trustworthy-registries-set-root/)

- [Prevent images that haven't been checked by a vulnerability scanner](https://kyverno.io/policies/other/require-vulnerability-scan/require-vulnerability-scan/)

- [Prevent ingress with the same host and path](https://kyverno.io/policies/other/unique-ingress-host-and-path/unique-ingress-host-and-path/)

---

## More about Kyverno

- Open source (https://github.com/kyverno/kyverno/)

- Compatible with all clusters

  (doesn't require to reconfigure the control plane, enable feature gates...)

- We don't endorse / support it in a particular way, but we think it's cool

- It's not the only solution!

  (see e.g. [Open Policy Agent](https://www.openpolicyagent.org/docs/v0.12.2/kubernetes-admission-control/) or [Validating Admission Policies](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/))

---

## How does it work?

- Kyverno is implemented as a *controller* or *operator*

- It typically runs as a Deployment on our cluster

- Policies are defined as *custom resources*

- They are implemented with a set of *dynamic admission control webhooks*

---

## Custom resource definitions

- When we install Kyverno, it will register new resource types, including:

  - Policy and ClusterPolicy (per-namespace and cluster-scope policies)

  - PolicyReport and ClusterPolicyReport (used in audit mode)

  - GenerateRequest (used internally when generating resources asynchronously)

- We will be able to do e.g. `kubectl get clusterpolicyreports --all-namespaces`

  (to see policy violations across all namespaces)

- Policies will be defined in YAML and registered/updated with e.g. `kubectl apply`

---

## Kyverno in action

- We're going to install Kyverno on our cluster

- Then, we will use it to implement a few policies

---

## Installing Kyverno

The recommended [installation method][install-kyverno] is to use Helm charts.

(It's also possible to install with a single YAML manifest.)

.lab[

- Install Kyverno:
  ```bash
    helm upgrade --install --repo https://kyverno.github.io/kyverno/ \
      --namespace kyverno --create-namespace kyverno kyverno
  ```

]

[install-kyverno]: https://kyverno.io/docs/installation/methods/

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

## Painting pods

- As an example, we'll implement a policy regarding "Pod color"

- The color of a Pod is the value of the label `color`

- Example: `kubectl label pod hello color=yellow` to paint a Pod in yellow

- We want to implement the following policies:

  - color is optional (i.e. the label is not required)

  - if color is set, it *must* be `red`, `green`, or `blue`

  - once the color has been set, it cannot be changed

  - once the color has been set, it cannot be removed

---

## Immutable primary colors, take 1

- First, we will add a policy to block forbidden colors

  (i.e. only allow `red`, `green`, or `blue`)

- One possible approach:

  - *match* all pods that have a `color` label that is not `red`, `green`, or `blue`

  - *deny* these pods

- We could also *match* all pods, then *deny* with a condition

---

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-1.yaml]
```
]

---

## Testing without the policy

- First, let's create a pod with an "invalid" label

  (while we still can!)

- We will use this later

.lab[

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

## Load and try the policy

.lab[

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

- Next rule: once a `color` label has been added, it cannot be changed

  (i.e. if `color=red`, we can't change it to `color=blue`)

- Our approach:

  - *match* all pods

  - add a *precondition* matching pods that have a `color` label
    <br/>
    (both in their "before" and "after" states)

  - *deny* these pods if their `color` label has changed

- Again, other approaches are possible!

---

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-2.yaml]
```
]

---

## Comparing "old" and "new"

- The fields of the webhook payload are available through `{{ request }}`

- For UPDATE requests, we can access:

  `{{ request.oldObject }}` → the object as it is right now (before the request)

  `{{ request.object }}` → the object with the changes made by the request

---

## Missing labels

- We can access the `color` label through `{{ request.object.metadata.labels.color }}`

- If we reference a label (or any field) that doesn't exist, the policy fails

  (with an error similar to `JMESPAth query failed: Unknown key ... in path`)

- If a precondition fails, the policy will be skipped altogether (and ignored!)

- To work around that, [use an OR expression][non-existence-checks]:

  `{{ requests.object.metadata.labels.color || '' }}`

- Note that in older versions of Kyverno, this wasn't always necessary

  (e.g. in *preconditions*, a missing label would evalute to an empty string)

[non-existence-checks]: https://kyverno.io/docs/policy-types/cluster-policy/jmespath/#non-existence-checks

---

## Load and try the policy

.lab[

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
  kubectl label pod test-color-2 color=purple
  kubectl label pod test-color-2 color=red
  kubectl label pod test-color-2 color=blue --overwrite
  ```

]

---

## `spec.rules.validate.failureAction`

- By default, this is set to `Audit`

- This means that rule violations are not enforced

- They still generate a warning (at the API level) and a PolicyReport

  (more on that later)

- We need to change the `failureAction` to `Enforce`

---

## `background`, `admission`, `emitWarning`

- Policies have three boolean flags to control what they do and when

- `admission` = run that policy at admission

  (when an object gets created/updated and validation controllers get invoked)

- `background` = run that policy in the background

  (periodically check if existing objects fit the policy)

- `emitWarning` = generate an `Event` of type `Warning` associated to the validated objct

  (visible with e.g. `kubectl describe` on that object)

---

## Background checks

- Admission controllers are only invoked when we change an object

- Existing objects are not affected

  (e.g. if we have a pod with `color=pink` *before* installing our policy)

- Kyvero can also run checks in the background, and report violations

  (we'll see later how they are reported)

- `background: true/false` controls that

- When would we want to disabled it? 🤔

---

## Accessing `AdmissionRequest` context

- In some of our policies, we want to prevent an *update*

  (as opposed to a mere *create* operation)

- We want to compare the *old* and *new* version

  (to check if a specific label was removed)

- The `AdmissionRequest` object has `object` and `oldObject` fields

  (the `AdmissionRequest` object is the thing that gets submitted to the webhook)

- We access the `AdmissionRequest` object through `{{ request }}`

---

## `{{ request }}`

- The `{{ request }}` context is only available when there is an `AdmissionRequest`

- When a resource is "at rest", there is no `{{ request }}` (and no old/new)

- Therefore, a policy that uses `{{ request }}` cannot validate existing objects

  (it can only be used when an object is actually created/updated/deleted)

--

- *Well, actually...*

--

- Kyverno exposes `{{ request.object }}` and `{{ request.namespace }}`

  (see [the documentation](https://kyverno.io/docs/policy-reports/background/) for details!)

---

## Immutable primary colors, take 3

- Last rule: once a `color` label has been added, it cannot be removed

- Our approach is to match all pods that:

  - *had* a `color` label (in `request.oldObject`)

  - *don't have* a `color` label (in `request.Object`)

- And *deny* these pods

- Again, other approaches are possible!

---

.small[
```yaml
@@INCLUDE[k8s/kyverno-pod-color-3.yaml]
```
]

---

## Load and try the policy

.lab[

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
  kubectl label pod test-color-3 color=purple
  kubectl label pod test-color-3 color=red
  kubectl label pod test-color-3 color-
  ```

]

---

## Background checks

- What about the `test-color-0` pod that we create initially?

  (remember: we did set `color=purple`)

- We can see the infringing Pod in a PolicyReport

.lab[

- Check that the pod still an "invalid" color:
  ```bash
  kubectl get pods -L color
  ```

- List PolicyReports:
  ```bash
  kubectl get policyreports
  kubectl get polr
  ```

]

(Sometimes it takes a little while for the infringement to show up, though.)

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

class: extra-details

## Managing `ownerReferences`

- By default, the generated object and triggering object have independent lifecycles

  (deleting the triggering object doesn't affect the generated object)

- It is possible to associate the generated object with the triggering object

  (so that deleting the triggering object also deletes the generated object)

- This is done by adding the triggering object information to `ownerReferences`

  (in the generated object `metadata`)

- See [Linking resources with ownerReferences][ownerref] for an example

[ownerref]: https://kyverno.io/docs/writing-policies/generate/#linking-trigger-with-downstream

---

## Asynchronous creation

- Kyverno creates resources asynchronously

  (by creating a GenerateRequest resource first)

- This is useful when the resource cannot be created

  (because of permissions or dependency issues)

- Kyverno will periodically loop through the pending GenerateRequests

- Once the ressource is created, the GenerateRequest is marked as Completed

---

## Footprint (current versions)

- 14 CRDs

- 10 webhooks

- 6 services, 4 Deployments, 2 ConfigMaps

- Internal resources (GenerateRequest) "parked" in a Namespace

---

## Footprint (older versions)

- 8 CRDs

- 5 webhooks

- 2 Services, 1 Deployment, 2 ConfigMaps

*We can see the number of resources increased over time, as Kyverno added features.*

---

## Strengths

- Kyverno is very easy to install

- The setup of the webhooks is fully automated

  (including certificate generation)

- It offers both namespaced and cluster-scope policies

- The policy language leverages existing constructs

  (e.g. `matchExpressions`)

- It has pretty good documentation, including many examples

- There is also a CLI tool (not discussed here)

---

## Caveats

- The `{{ request }}` context is powerful, but difficult to validate

  (Kyverno can't know ahead of time how it will be populated)

- Advanced policies (with conditionals) have unique, exotic syntax:
  ```yaml
      spec:
	    =(volumes):
	      =(hostPath):
	        path: "!/var/run/docker.sock"
  ```

- Writing and validating policies can be difficult

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
