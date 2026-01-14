# Policy Management with Kyverno

- Kyverno is a policy engine for Kubernetes

- It has many use cases, including:

  - enforcing or giving warnings about best practices or misconfigurations
    <br/>(e.g. `:latest` images, healthchecks, requests and limits...)

  - tightening security
    <br/>(possibly for multitenant clusters)

  - preventing some modifications
    <br/>(e.g. restricting modifications to some fields, labels...)

  - modifying, generating, cleaning up resources automatically

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

  - *match* and/or *exclude* resources

  - match by *kind*, *selector*, *namespace selector*, user/roles doing the action...

- Which operation should be done?

  - validate, mutate, or generate

- For validation, whether it should *enforce* or *audit* failures

- Operation details (what exactly to validate, mutate, or generate)

---

## Validating objects

Example: [require resource requests and limits][kyverno-requests-limits].

```yaml
validate:
  message: "CPU and memory resource requests and memory limits are required."
  pattern:
    spec:
      containers:
      - resources:
          requests:
            memory: "?*"
            cpu: "?*"
          limits:
            memory: "?*"
```

(The full policy also has sections for `initContainers` and `ephemeralContainers`.)

[kyverno-requests-limits]: https://kyverno.io/policies/best-practices/require-pod-requests-limits/require-pod-requests-limits/

---

## Optional fields

Example: [disallow `NodePort` Services][kyverno-disallow-nodeports].

```yaml
validate:
  message: "Services of type NodePort are not allowed."
  pattern:
    spec:
      =(type): "!NodePort"
```

`=(...):` means that the field is optional.

`type: "!NodePort"` would *require* the field to exist, but be different from `NodePort`.

[kyverno-disallow-nodeports]: https://kyverno.io/policies/best-practices/restrict-node-port/restrict-node-port/

---

## `spec.rules.validate.failureAction`

- By default, this is set to `Audit`

- This means that rule violations are not enforced

- They still generate a warning (at the API level) and a PolicyReport

  (more on that later)

- We (very often) need to change the `failureAction` to `Enforce`

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

  (e.g. if we create "invalid" objects *before* installing the policy)

- Kyvero can also run checks in the background, and report violations

  (we'll see later how they are reported)

- `background: true/false` controls that

---

## Loops

Example: [require image tags][kyverno-disallow-latest].

This uses `request`, which gives access to the `AdmissionRequest` payload.

`request` has an `object` field containing the object that we're validating.

```yaml
validate:
  message: "An image tag is required."
  foreach:
    - list: "request.object.spec.containers"
      pattern:
        image: "*:*"
```

Note: again, there should also be an entry for `initContainers` and `ephemeralContainers`.

[kyverno-disallow-latest]: https://kyverno.io/policies/best-practices/disallow-latest-tag/disallow-latest-tag/

---

class: extra-details

## ...Or not to loop

Requiring image tags can also be achieved like this:

```yaml
validate:
  message: "An image tag is required."
  pattern:
    spec:
      containers:
      - image: "*:*"
      =(initContainers):
      - image: "*:*"
      =(ephemeralContainers):
      - image: "*:*"
```

---

## `request` and other variables

- `request` gives us access to the `AdmissionRequest` payload

- This gives us access to a bunch of interesting fields:

  `request.operation`: CREATE, UPDATE, DELETE, or CONNECT

  `request.object`: the object being created or modified

  `request.oldObject`: the object being modified (only for UPDATE)

  `request.userInfo`: information about the user making the API request

- `object` and `oldObject` are very convenient to block specific *modifications*

  (e.g. making some labels or annotations immutable)

(See [here][kyverno-request] for details.)

[kyverno-request]: https://kyverno.io/docs/policy-types/cluster-policy/variables/#variables-from-admission-review-requests

---

## Generating objects

- Let's review a fairly common use-case...

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

## Templates and JMESpath

- We can use `{{ }}` templates in Kyverno policies

  (when generating or validating resources; in conditions, pre-conditions...)

- This lets us access `request` as well as [a few other variables][kyverno-variables]

- We can also use JMESPath expressions, for instance:

  `{{request.object.spec.containers[?name=='worker'].image}}`

  `{{request.object.spec.[containers,initContainers][][].image}}`

- To experiment with JMESPath, use e.g. [jmespath.org] or [install the kyverno CLI][kyverno-cli]

  (then use `kubectl kyverno jp query < data.json ...expression... `)

[jmespath.org]: https://jmespath.org/
[kyverno-cli]: https://kyverno.io/docs/kyverno-cli/install/
[kyverno-variables]: https://kyverno.io/docs/policy-types/cluster-policy/variables/#pre-defined-variables

---

## Data sources

- It's also possible to access data in Kubernetes ConfigMaps:
  ```yaml
    context:
    - name: ingressconfig
      configMap:
        name: ingressconfig
        namespace: {{request.object.metadata.namespace}}
  ```

- And then use it e.g. in a policy generating or modifying Ingress resources:
  ```yaml
  ...
  host: {{request.object.metadata.name}}.{{ingressconfig.data.domainsuffix}}
  ...
  ```

---

## Kubernetes API calls

- It's also possible to access arbitrary Kubernetes resources through API calls:
  ```yaml
    context:
    - name: dns
      apiCall:
        urlPath: "/api/v1/namespaces/kube-system/services/kube-dns"
        jmesPath: "spec.clusterIP"
  ```

- And then use that e.g. in a mutating policy:
  ```yaml
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            env:
            - name: DNS
              value: "{{dns}}"
  ```

---

## Lifecycle

- After generated objects have been created, we can change them

  (Kyverno won't automatically revert them)

- Except if we use `clone` together with the `synchronize` flag

  (in that case, Kyverno will watch the cloned resource)

- This is convenient for e.g. ConfigMaps shared between Namespaces

---

class: extra-details

## Managing `ownerReferences`

- By default, the generated object and triggering object have independent lifecycles

  (deleting the triggering object doesn't affect the generated object)

- It is possible to associate the generated object with the triggering object

  (so that deleting the triggering object also deletes the generated object)

- This is done by adding the triggering object information to `ownerReferences`

  (in the generated object `metadata`)

- See [Linking resources with ownerReferences][kyverno-ownerref] for an example

[kyverno-ownerref]: https://kyverno.io/docs/policy-types/cluster-policy/generate/#linking-trigger-with-downstream

---

class: extra-details

## Asynchronous creation

- Kyverno creates resources asynchronously

  (by creating a GenerateRequest resource first)

- This is useful when the resource cannot be created

  (because of permissions or dependency issues)

- Kyverno will periodically loop through the pending GenerateRequests

- Once the ressource is created, the GenerateRequest is marked as Completed

---

class: extra-details

## Autogen rules for Pod validating policies

- In Kubernetes, we rarely create Pods directly

  (instead, we create controllers like Deployments, DaemonSets, Jobs, etc)

- As a result, Pod validating policies can be tricky to debug

  (the policy blocks invalid Pods, but doesn't block their controller)

- Kyverno helps us with "autogen rules"

  (when we create a Pod policy, it will automatically create policies on Pod controllers)

- This can be customized if needed; [see documentation for details][kyverno-autogen]

  (it can be disabled, or extended to Custom Resources)

[kyverno-autogen]: https://kyverno.io/docs/policy-types/cluster-policy/autogen/

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

- It continues to evolve and gain new features

???

:EN:- Policy Management with Kyverno
:FR:- Gestion de *policies* avec Kyverno
