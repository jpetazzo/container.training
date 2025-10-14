# Extending the Kubernetes API

There are multiple ways to extend the Kubernetes API.

We are going to cover:

- Controllers

- Admission Control

- Custom Resource Definitions (CRDs)

- The Aggregation Layer

But first, let's re(re)visit the API server ...

---

## Revisiting the API server

- The Kubernetes API server is a central point of the control plane

- Everything connects to the API server:

  - users (that's us, but also automation like CI/CD)

  - kubelets

  - network components (e.g. `kube-proxy`, pod network, NPC)

  - controllers; lots of controllers

---

## Some controllers

- `kube-controller-manager` runs built-on controllers

  (watching Deployments, Nodes, ReplicaSets, and much more)

- `kube-scheduler` runs the scheduler

  (it's conceptually not different from another controller)

- `cloud-controller-manager` takes care of "cloud stuff"

  (e.g. provisioning load balancers, persistent volumes...)

- Some components mentioned above are also controllers

  (e.g. Network Policy Controller)

---

## More controllers

- Cloud resources can also be managed by additional controllers

  (e.g. the [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller))

- Leveraging Ingress resources requires an Ingress Controller

  (many options available here; we can even install multiple ones!)

- Many add-ons (including CRDs and operators) have controllers as well

🤔 *What's even a controller ?!?*

---

## What's a controller?

According to the [documentation](https://kubernetes.io/docs/concepts/architecture/controller/):

*Controllers are **control loops** that<br/>
**watch** the state of your cluster,<br/>
then make or request changes where needed.*

*Each controller tries to move the current cluster state closer to the desired state.*

---

## What controllers do

- Watch resources

- Make changes:

  - purely at the API level (e.g. Deployment, ReplicaSet controllers)

  - and/or configure resources (e.g. `kube-proxy`)

  - and/or provision resources (e.g. load balancer controller)

---

## Extending Kubernetes with controllers

- Random example:

  - watch resources like Deployments, Services ...

  - read annotations to configure monitoring

- Technically, this is not extending the API

  (but it can still be very useful!)

---

## Other ways to extend Kubernetes

- Prevent or alter API requests before resources are committed to storage:

  *Admission Control*

- Create new resource types leveraging Kubernetes storage facilities:

  *Custom Resource Definitions*

- Create new resource types with different storage or different semantics:

  *Aggregation Layer*

- Spoiler alert: often, we will combine multiple techniques

  (and involve controllers as well!)

---

## Admission control

- Validate (approve/deny) or mutate (modify) API requests

- In modern Kubernetes, we have at least 3 ways to achieve that:

  - [admission controllers][ac-controllers] (built in the API server)

  - [dynamic admission control][ac-webhooks] (with webhooks)

  - [validating admission policies][ac-vap] (using CEL, Common Expression Language)

- More is coming; e.g. [mutating admission policies][ac-map]

  (alpha in Kubernetes 1.32, beta in Kubernetes 1.34)

[ac-controllers]: https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/
[ac-webhooks]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/
[ac-vap]: https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/
[ac-map]: https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/

---

class: pic

![API request lifecycle; from Kubernetes documentation](images/admission-control-phases.svg)

---

## Admission controllers

- Built in the API server

- *Validating* admission controllers can accept/reject the API call

- *Mutating* admission controllers can modify the API request payload

- Both types can also trigger additional actions

  (e.g. automatically create a Namespace if it doesn't exist)

- There are a number of built-in admission controllers

  ([and a bunch of them are enabled by default][ac-default])

- They can be enabled/disabled with API server command-line flags

  (this is not always possible when using *managed* Kubernetes!)

[ac-default]: https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#which-plugins-are-enabled-by-default

---

class: extra-details

## Some built-in admission controllers

- ServiceAccount:

  automatically adds a ServiceAccount to Pods that don't explicitly specify one

- LimitRanger:

  applies resource constraints specified by LimitRange objects when Pods are created

- NamespaceAutoProvision:

  automatically creates namespaces when an object is created in a non-existent namespace

*Note: #1 and #2 are enabled by default; #3 is not.*

---

## Dynamic Admission Control

- We can set up *admission webhooks* to extend the behavior of the API server

- The API server will submit incoming API requests to these webhooks

- These webhooks can be *validating* or *mutating*

- Webhooks can be set up dynamically (without restarting the API server)

- To setup a dynamic admission webhook, we create a special resource:

  a `ValidatingWebhookConfiguration` or a `MutatingWebhookConfiguration`

- These resources are created and managed like other resources

  (i.e. `kubectl create`, `kubectl get`...)

---

class: extra-details

## Webhook Configuration

- A ValidatingWebhookConfiguration or MutatingWebhookConfiguration contains:

  - the address of the webhook

  - the authentication information to use with the webhook

  - a list of rules

- The rules indicate for which objects and actions the webhook is triggered

  (to avoid e.g. triggering webhooks when setting up webhooks)

- The webhook server can be hosted in or out of the cluster

---

## Dynamic Admission Examples

- Policy control

  ([Kyverno](https://kyverno.io/),
  [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/))

- Sidecar injection

  (used by some service meshes)

- Type validation

  (more on this later, in the CRD section)

- And many other creative + useful scenarios!

  (for example in [kube-image-keeper][kuik], to rewrite image references)

[kuik]: https://github.com/enix/kube-image-keeper

---

## Validating Admission Policies

- Relatively recent (alpha: 1.26, beta: 1.28, GA: 1.30)

- Declare validation rules with Common Expression Language (CEL)

- Validation is done entirely within the API server

  (no external webhook = no latency, no deployment complexity...)

- Not as powerful as full-fledged webhook engines like Kyverno

  (see e.g. [this page of the Kyverno doc][kyverno-vap] for a comparison)

[kyverno-vap]: https://kyverno.io/docs/policy-types/validating-policy/

---

## Kubernetes API resource types

- Almost everything in Kubernetes is materialized by a resource

- Resources have a type (or "kind")

  (similar to strongly typed languages)

- We can see existing types with `kubectl api-resources`

- We can list resources of a given type with `kubectl get <type>`

---

## Creating new types

- We can create new types with Custom Resource Definitions (CRDs)

- CRDs are created dynamically

  (without recompiling or restarting the API server)

- CRDs themselves are resources:

  - we can create a new type with `kubectl create` and some YAML

  - we can see all our custom types with `kubectl get crds`

- After we create a CRD, the new type works just like built-in types

---

## Examples

- Representing configuration for controllers and operators

  (e.g. Prometheus scrape targets, gitops configuration, certificates...)

- Representing composite resources

  (e.g. database cluster, message queue...)

- Representing external resources

  (e.g. virtual machines, object store buckets, domain names...)

- Alternate representations of other objects; services and service instances

  (e.g. encrypted secret, git endpoints...)

---

## The aggregation layer

- We can delegate entire parts of the Kubernetes API to external servers

- This is done by creating APIService resources

  (check them with `kubectl get apiservices`!)

- The APIService resource maps a type (kind) and version to an external service

- All requests concerning that type are sent (proxied) to the external service

- This allows to have resources like CRDs, but that aren't stored in etcd

- Example: `metrics-server`

---

## Why?

- Using a CRD for live metrics would be extremely inefficient

  (etcd **is not** a metrics store; write performance is way too slow)

- Instead, `metrics-server`:

  - collects metrics from kubelets

  - stores them in memory

  - exposes them as PodMetrics and NodeMetrics (in API group metrics.k8s.io)

  - is registered as an APIService

---

## Drawbacks

- Requires a server

- ... that implements a non-trivial API (aka the Kubernetes API semantics)

- If we need REST semantics, CRDs are probably way simpler

- *Sometimes* synchronizing external state with CRDs might do the trick

  (unless we want the external state to be our single source of truth)

---

## And more...

- Some specifics areas of Kubernetes also have extension points

- Example: scheduler

  - it's possible to [customize the behavior of the scheduler][sched-config]

  - or even run [multiple schedulers][sched-multiple]

[sched-config]: https://kubernetes.io/docs/reference/scheduling/config/
[sched-multiple]: https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

???

:EN:- Overview of Kubernetes API extensions
:FR:- Comment étendre l'API Kubernetes
