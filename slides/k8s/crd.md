# Custom Resource Definitions

- CRDs are one of the (many) ways to extend the API

- CRDs can be defined dynamically

  (no need to recompile or reload the API server)

- A CRD is defined with a CustomResourceDefinition resource

  (CustomResourceDefinition is conceptually similar to a *metaclass*)

---

## A very simple CRD

The YAML below describes a very simple CRD representing different kinds of coffee:

@@LINK[k8s/coffee-1.yaml]

```yaml
@@INCLUDE[k8s/coffee-1.yaml]
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

???

:EN:- Custom Resource Definitions (CRDs)
:FR:- Les CRDs *(Custom Resource Definitions)*
