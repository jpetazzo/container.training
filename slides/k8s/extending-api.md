# Extending the Kubernetes API

There are multiple ways to extend the Kubernetes API.

We are going to cover:

- Controllers

- Dynamic Admission Webhooks

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

## Admission controllers

- Admission controllers can vet or transform API requests

- The diagram on the next slide shows the path of an API request

  (courtesy of Banzai Cloud)

---

class: pic

![API request lifecycle](images/api-request-lifecycle.png)

---

## Types of admission controllers

- *Validating* admission controllers can accept/reject the API call

- *Mutating* admission controllers can modify the API request payload

- Both types can also trigger additional actions

  (e.g. automatically create a Namespace if it doesn't exist)

- There are a number of built-in admission controllers

  (see [documentation](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#what-does-each-admission-controller-do) for a list)

- We can also dynamically define and register our own

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

  (Used by some service meshes)

- Type validation

  (More on this later, in the CRD section)

---

## Kubernetes API types

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

- Representing composite resources

  (e.g. clusters like databases, messages queues ...)

- Representing external resources

  (e.g. virtual machines, object store buckets, domain names ...)

- Representing configuration for controllers and operators

  (e.g. custom Ingress resources, certificate issuers, backups ...)

- Alternate representations of other objects; services and service instances

  (e.g. encrypted secret, git endpoints ...)

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

## Service catalog

- *Service catalog* is another extension mechanism

- It's not extending the Kubernetes API strictly speaking

  (but it still provides new features!)

- It doesn't create new types; it uses:

  - ClusterServiceBroker
  - ClusterServiceClass
  - ClusterServicePlan
  - ServiceInstance
  - ServiceBinding

- It uses the Open service broker API

---

## Documentation

- [Custom Resource Definitions: when to use them](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)

- [Custom Resources Definitions: how to use them](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/)

- [Service Catalog](https://kubernetes.io/docs/concepts/extend-kubernetes/service-catalog/)

- [Built-in Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

- [Dynamic Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

- [Aggregation Layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)

???

:EN:- Overview of Kubernetes API extensions
:FR:- Comment étendre l'API Kubernetes
