# Extending the Kubernetes API

There are multiple ways to extend the Kubernetes API.

We are going to cover:

- Custom Resource Definitions (CRDs)

- Admission Webhooks

- The Aggregation Layer

---

## Revisiting the API server

- The Kubernetes API server is a central point of the control plane

  (everything connects to it: controller manager, scheduler, kubelets)

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

## A very simple CRD

The YAML below describes a very simple CRD representing different kinds of coffee:

```yaml
apiVersion: apiextensions.k8s.io/v1alpha1
kind: CustomResourceDefinition
metadata:
  name: coffees.container.training
spec:
  group: container.training
  version: v1alpha1
  scope: Namespaced
  names:
    plural: coffees
    singular: coffee
    kind: Coffee
    shortNames:
    - cof
```

---

## Creating a CRD

- Let's create the Custom Resource Definition for our Coffee resource

.exercise[

- Load the CRD:
  ```bash
  kubectl apply -f ~/container.training/k8s/coffee-1.yaml
  ```

- Confirm that it shows up:
  ```bash
  kubectl get crds
  ```

]

---

## Creating custom resources

The YAML below defines a resource using the CRD that we just created:

```yaml
kind: Coffee
apiVersion: container.training/v1alpha1
metadata:
  name: arabica
spec:
  taste: strong
```

.exercise[

- Create a few types of coffee beans:
  ```bash
  kubectl apply -f ~/container.training/k8s/coffees.yaml
  ```

]

---

## Viewing custom resources

- By default, `kubectl get` only shows name and age of custom resources

.exercise[

- View the coffee beans that we just created:
  ```bash
  kubectl get coffees
  ```

]

- We can improve that, but it's outside the scope of this section!

---

## What can we do with CRDs?

There are many possibilities!

- *Operators* encapsulate complex sets of resources

  (e.g.: a PostgreSQL replicated cluster; an etcd cluster...
  <br/>
  see [awesome operators](https://github.com/operator-framework/awesome-operators) and
  [OperatorHub](https://operatorhub.io/) to find more)

- Custom use-cases like [gitkube](https://gitkube.sh/)

  - creates a new custom type, `Remote`, exposing a git+ssh server

  - deploy by pushing YAML or Helm charts to that remote

- Replacing built-in types with CRDs

  (see [this lightning talk by Tim Hockin](https://www.youtube.com/watch?v=ji0FWzFwNhA))

---

## Little details

- By default, CRDs are not *validated*

  (we can put anything we want in the `spec`)

- When creating a CRD, we can pass an OpenAPI v3 schema (BETA!)

  (which will then be used to validate resources)

- Generally, when creating a CRD, we also want to run a *controller*

  (otherwise nothing will happen when we create resources of that type)

- The controller will typically *watch* our custom resources

  (and take action when they are created/updated)

*
Examples:
[YAML to install the gitkube CRD](https://storage.googleapis.com/gitkube/gitkube-setup-stable.yaml),
[YAML to install a redis operator CRD](https://github.com/amaizfinance/redis-operator/blob/master/deploy/crds/k8s_v1alpha1_redis_crd.yaml)
*

---

## (Ab)using the API server

- If we need to store something "safely" (as in: in etcd), we can use CRDs

- This gives us primitives to read/write/list objects (and optionally validate them)

- The Kubernetes API server can run on its own

  (without the scheduler, controller manager, and kubelets)

- By loading CRDs, we can have it manage totally different objects

  (unrelated to containers, clusters, etc.)

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

## Admission controllers

- Admission controllers are another way to extend the Kubernetes API

- Instead of creating new types, admission controllers can transform or vet API requests

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

## Admission Webhooks

- We can setup *admission webhooks* to extend the behavior of the API server

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

---

## The aggregation layer

- We can delegate entire parts of the Kubernetes API to external servers

- This is done by creating APIService resources

  (check them with `kubectl get apiservices`!)

- The APIService resource maps a type (kind) and version to an external service

- All requests concerning that type are sent (proxied) to the external service

- This allows to have resources like CRDs, but that aren't stored in etcd

- Example: `metrics-server`

  (storing live metrics in etcd would be extremely inefficient)

- Requires significantly more work than CRDs!

---

## Documentation

- [Custom Resource Definitions: when to use them](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)

- [Custom Resources Definitions: how to use them](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/)

- [Service Catalog](https://kubernetes.io/docs/concepts/extend-kubernetes/service-catalog/)

- [Built-in Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

- [Dynamic Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

- [Aggregation Layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)
