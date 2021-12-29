# Custom Resource Definitions

- CRDs are one of the (many) ways to extend the API

- CRDs can be defined dynamically

  (no need to recompile or reload the API server)

- A CRD is defined with a CustomResourceDefinition resource

  (CustomResourceDefinition is conceptually similar to a *metaclass*)

---

## Creating a CRD

- We will create a CRD to represent the different species of coffee

  (arabica, liberica, and robusta)

- We will be able to run `kubectl get coffees` and it will list the species

- Then we can label, edit, etc. the species to attach some information

  (e.g. the taste profile of the coffee, or whatever we want)

---

## First shot of coffee

```yaml
@@INCLUDE[k8s/coffee-1.yaml]
```

---

## The joys of API deprecation

- Unfortunately, the CRD manifest on the previous slide is deprecated!

- It is using `apiextensions.k8s.io/v1beta1`, which is dropped in Kubernetes 1.22

- We need to use `apiextensions.k8s.io/v1`, which is a little bit more complex

  (a few optional things become mandatory, see [this guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#customresourcedefinition-v122) for details)

- `apiextensions.k8s.io/v1beta1` is available since Kubernetes 1.16

---

## Second shot of coffee

- The next slide will show file @@LINK[k8s/coffee-2.yaml]

- Note the `spec.versions` list

  - we need exactly one version with `storage: true`

  - we can have multiple versions with `served: true`

- `spec.versions[].schema.openAPI3Schema` is required

  (and must be a valid OpenAPI schema; here it's a trivial one)

---

```yaml
@@INCLUDE[k8s/coffee-2.yaml]
```

---

## Creating our Coffee CRD

- Let's create the Custom Resource Definition for our Coffee resource

.lab[

- Load the CRD:
  ```bash
  kubectl apply -f ~/container.training/k8s/coffee-2.yaml
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

.lab[

- Create a few types of coffee beans:
  ```bash
  kubectl apply -f ~/container.training/k8s/coffees.yaml
  ```

]

---

## Viewing custom resources

- By default, `kubectl get` only shows name and age of custom resources

.lab[

- View the coffee beans that we just created:
  ```bash
  kubectl get coffees
  ```

]

- We'll see in a bit how to improve that

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

## What's next?

- Creating a basic CRD is quick and easy

- But there is a lot more that we can (and probably should) do:

  - improve input with *data validation*

  - improve output with *custom columns*

- And of course, we probably need a *controller* to go with our CRD!

  (otherwise, we're just using the Kubernetes API as a fancy data store)

---

## Additional printer columns

- We can specify `additionalPrinterColumns` in the CRD

- This is similar to `-o custom-columns`

  (map a column name to a path in the object, e.g. `.spec.taste`)

```yaml
    additionalPrinterColumns:
    - jsonPath: .spec.taste
      description: Subjective taste of that kind of coffee bean
      name: Taste
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
```

---

## Using additional printer columns

- Let's update our CRD using @@LINK[k8s/coffee-3.yaml]

.lab[

- Update the CRD:
  ```bash
  kubectl apply -f ~/container.training/k8s/coffee-3.yaml
  ```

- Look at our Coffee resources:
  ```bash
  kubectl get coffees
  ```

]

Note: we can update a CRD without having to re-create the corresponding resources.

(Good news, right?)

---

## Data validation

- CRDs are validated with the OpenAPI v3 schema that we specify

  (with older versions of the API, when the schema was optional,
  <br/>
  no schema = no validation at all)

- Otherwise, we can put anything we want in the `spec`

- More advanced validation can also be done with admission webhooks, e.g.:

  - consistency between parameters

  - advanced integer filters (e.g. odd number of replicas)

  - things that can change in one direction but not the other

---

## OpenAPI v3 schema example

This is what we have in @@LINK[k8s/coffee-3.yaml]:

```yaml
    schema:
      openAPIV3Schema:
        type: object
        required: [ spec ]
        properties:
          spec:
            type: object
            properties:
              taste:
                description: Subjective taste of that kind of coffee bean
                type: string
            required: [ taste ]
```

---

## Validation *a posteriori*

- Some of the "coffees" that we defined earlier *do not* pass validation

- How is that possible?

--

- Validation happens at *admission*

  (when resources get written into the database)

- Therefore, we can have "invalid" resources in etcd

  (they are invalid from the CRD perspective, but the CRD can be changed)

🤔 How should we handle that ?

---

## Versions

- If the data format changes, we can roll out a new version of the CRD

  (e.g. go from `v1alpha1` to `v1alpha2`)

- In a CRD we can specify the versions that exist, that are *served*, and *stored*

  - multiple versions can be *served*

  - only one can be *stored*

- Kubernetes doesn't automatically migrate the content of the database

- However, it can convert between versions when resources are read/written

---

## Conversion

- When *creating* a new resource, the *stored* version is used

  (if we create it with another version, it gets converted)

- When *getting* or *watching* resources, the *requested* version is used

  (if it is stored with another version, it gets converted)

- By default, "conversion" only changes the `apiVersion` field

- ... But we can register *conversion webhooks*

  (see [that doc page](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/#webhook-conversion) for details)

---

## Migrating database content

- We need to *serve* a version as long as we *store* objects in that version

  (=as long as the database has at least one object with that version)

- If we want to "retire" a version, we need to migrate these objects first

- All we have to do is to read and re-write them

  (the [kube-storage-version-migrator](https://github.com/kubernetes-sigs/kube-storage-version-migrator) tool can help)

---

## What's next?

- Generally, when creating a CRD, we also want to run a *controller*

  (otherwise nothing will happen when we create resources of that type)

- The controller will typically *watch* our custom resources

  (and take action when they are created/updated)

---

## CRDs in the wild

- [gitkube](https://storage.googleapis.com/gitkube/gitkube-setup-stable.yaml)

- [A redis operator](https://github.com/amaizfinance/redis-operator/blob/master/deploy/crds/k8s_v1alpha1_redis_crd.yaml)

- [cert-manager](https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml)

*How big are these YAML files?*

*What's the size (e.g. in lines) of each resource?*

---

## CRDs in practice

- Production-grade CRDs can be extremely verbose

  (because of the openAPI schema validation)

- This can (and usually will) be managed by a framework

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
