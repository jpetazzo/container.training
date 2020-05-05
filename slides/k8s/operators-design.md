# Designing an operator

- Once we understand CRDs and operators, it's tempting to use them everywhere

- Yes, we can do (almost) everything with operators ...

- ... But *should we?*

- Very often, the answer is **“no!”**

- Operators are powerful, but significantly more complex than other solutions

---

## When should we (not) use operators?

- Operators are great if our app needs to react to cluster events

  (nodes or pods going down, and requiring extensive reconfiguration)

- Operators *might* be helpful to encapsulate complexity

  (manipulate one single custom resource for an entire stack)

- Operators are probably overkill if a Helm chart would suffice

- That being said, if we really want to write an operator ...

  Read on!

---

## What does it take to write an operator?

- Writing a quick-and-dirty operator, or a POC/MVP, is easy

- Writing a robust operator is hard

- We will describe the general idea

- We will identify some of the associated challenges

- We will list a few tools that can help us

---

## Top-down vs. bottom-up

- Both approaches are possible

- Let's see what they entail, and their respective pros and cons

---

## Top-down approach

- Start with high-level design (see next slide)

- Pros:

  - can yield cleaner design that will be more robust

- Cons:

  - must be able to anticipate all the events that might happen

  - design will be better only to the extent of what we anticipated

  - hard to anticipate if we don't have production experience

---

## High-level design

- What are we solving?

  (e.g.: geographic databases backed by PostGIS with Redis caches)

- What are our use-cases, stories?

  (e.g.: adding/resizing caches and read replicas; load balancing queries)

- What kind of outage do we want to address?

  (e.g.: loss of individual node, pod, volume)

- What are our *non-features*, the things we don't want to address?

  (e.g.: loss of datacenter/zone; differentiating between read and write queries;
  <br/>
  cache invalidation; upgrading to newer major versions of Redis, PostGIS, PostgreSQL)

---

## Low-level design

- What Custom Resource Definitions do we need?

  (one, many?)

- How will we store configuration information?

  (part of the CRD spec fields, annotations, other?)

- Do we need to store state? If so, where?

  - state that is small and doesn't change much can be stored via the Kubernetes API
    <br/>
    (e.g.: leader information, configuration, credentials)

  - things that are big and/or change a lot should go elsewhere
    <br/>
    (e.g.: metrics, bigger configuration file like GeoIP)

---

class: extra-details

## What can we store via the Kubernetes API?

- The API server stores most Kubernetes resources in etcd

- Etcd is designed for reliability, not for performance

- If our storage needs exceed what etcd can offer, we need to use something else:

  - either directly

  - or by extending the API server
    <br/>(for instance by using the agregation layer, like [metrics server](https://github.com/kubernetes-incubator/metrics-server) does)

---

## Bottom-up approach

- Start with existing Kubernetes resources (Deployment, Stateful Set...)

- Run the system in production

- Add scripts, automation, to facilitate day-to-day operations

- Turn the scripts into an operator

- Pros: simpler to get started; reflects actual use-cases

- Cons: can result in convoluted designs requiring extensive refactor

---

## General idea

- Our operator will watch its CRDs *and associated resources*

- Drawing state diagrams and finite state automata helps a lot

- It's OK if some transitions lead to a big catch-all "human intervention"

- Over time, we will learn about new failure modes and add to these diagrams

- It's OK to start with CRD creation / deletion and prevent any modification

  (that's the easy POC/MVP we were talking about)

- *Presentation* and *validation* will help our users

  (more on that later)

---

## Challenges

- Reacting to infrastructure disruption can seem hard at first

- Kubernetes gives us a lot of primitives to help:

  - Pods and Persistent Volumes will *eventually* recover

  - Stateful Sets give us easy ways to "add N copies" of a thing

- The real challenges come with configuration changes

  (i.e., what to do when our users update our CRDs)

- Keep in mind that [some] of the [largest] cloud [outages] haven't been caused by [natural catastrophes], or even code bugs, but by configuration changes

[some]: https://www.datacenterdynamics.com/news/gcp-outage-mainone-leaked-google-cloudflare-ip-addresses-china-telecom/
[largest]: https://aws.amazon.com/message/41926/
[outages]: https://aws.amazon.com/message/65648/
[natural catastrophes]: https://www.datacenterknowledge.com/amazon/aws-says-it-s-never-seen-whole-data-center-go-down

---

## Configuration changes

- It is helpful to analyze and understand how Kubernetes controllers work:

  - watch resource for modifications

  - compare desired state (CRD) and current state

  - issue actions to converge state

- Configuration changes will probably require *another* state diagram or FSA

- Again, it's OK to have transitions labeled as "unsupported"

  (i.e. reject some modifications because we can't execute them)

---

## Tools

- CoreOS / RedHat Operator Framework

  [GitHub](https://github.com/operator-framework)
  |
  [Blog](https://developers.redhat.com/blog/2018/12/18/introduction-to-the-kubernetes-operator-framework/)
  |
  [Intro talk](https://www.youtube.com/watch?v=8k_ayO1VRXE)
  |
  [Deep dive talk](https://www.youtube.com/watch?v=fu7ecA2rXmc)
  |
  [Simple example](https://medium.com/faun/writing-your-first-kubernetes-operator-8f3df4453234)

- Zalando Kubernetes Operator Pythonic Framework (KOPF)

  [GitHub](https://github.com/zalando-incubator/kopf)
  |
  [Docs](https://kopf.readthedocs.io/)
  |
  [Step-by-step tutorial](https://kopf.readthedocs.io/en/stable/walkthrough/problem/)

- Mesosphere Kubernetes Universal Declarative Operator (KUDO)

  [GitHub](https://github.com/kudobuilder/kudo)
  |
  [Blog](https://mesosphere.com/blog/announcing-maestro-a-declarative-no-code-approach-to-kubernetes-day-2-operators/)
  |
  [Docs](https://kudo.dev/)
  |
  [Zookeeper example](https://github.com/kudobuilder/frameworks/tree/master/repo/stable/zookeeper)

---

## Validation

- By default, a CRD is "free form"

  (we can put pretty much anything we want in it)

- When creating a CRD, we can provide an OpenAPI v3 schema
  ([Example](https://github.com/amaizfinance/redis-operator/blob/master/deploy/crds/k8s_v1alpha1_redis_crd.yaml#L34))

- The API server will then validate resources created/edited with this schema

- If we need a stronger validation, we can use a Validating Admission Webhook:

  - run an [admission webhook server](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#write-an-admission-webhook-server) to receive validation requests

  - register the webhook by creating a [ValidatingWebhookConfiguration](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#configure-admission-webhooks-on-the-fly)

  - each time the API server receives a request matching the configuration,
    <br/>the request is sent to our server for validation

---

## Presentation

- By default, `kubectl get mycustomresource` won't display much information

  (just the name and age of each resource)

- When creating a CRD, we can specify additional columns to print
  ([Example](https://github.com/amaizfinance/redis-operator/blob/master/deploy/crds/k8s_v1alpha1_redis_crd.yaml#L6),
  [Docs](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#additional-printer-columns))

- By default, `kubectl describe mycustomresource` will also be generic

- `kubectl describe` can show events related to our custom resources

  (for that, we need to create Event resources, and fill the `involvedObject` field)

- For scalable resources, we can define a `scale` sub-resource

- This will enable the use of `kubectl scale` and other scaling-related operations

---

## About scaling

- It is possible to use the HPA (Horizontal Pod Autoscaler) with CRDs

- But it is not always desirable

- The HPA works very well for homogenous, stateless workloads

- For other workloads, your mileage may vary

- Some systems can scale across multiple dimensions

  (for instance: increase number of replicas, or number of shards?)

- If autoscaling is desired, the operator will have to take complex decisions

  (example: Zalando's Elasticsearch Operator ([Video](https://www.youtube.com/watch?v=lprE0J0kAq0)))

---

## Versioning

- As our operator evolves over time, we may have to change the CRD

  (add, remove, change fields)

- Like every other resource in Kubernetes, [custom resources are versioned](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definition-versioning/
)

- When creating a CRD, we need to specify a *list* of versions

- Versions can be marked as `stored` and/or `served`

---

## Stored version

- Exactly one version has to be marked as the `stored` version

- As the name implies, it is the one that will be stored in etcd

- Resources in storage are never converted automatically

  (we need to read and re-write them ourselves)

- Yes, this means that we can have different versions in etcd at any time

- Our code needs to handle all the versions that still exist in storage

---

## Served versions

- By default, the Kubernetes API will serve resources "as-is"

  (using their stored version)

- It will assume that all versions are compatible storage-wise

  (i.e. that the spec and fields are compatible between versions)

- We can provide [conversion webhooks](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definition-versioning/#webhook-conversion) to "translate" requests

  (the alternative is to upgrade all stored resources and stop serving old versions)

---

## Operator reliability

- Remember that the operator itself must be resilient

  (e.g.: the node running it can fail)

- Our operator must be able to restart and recover gracefully

- Do not store state locally

  (unless we can reconstruct that state when we restart)

- As indicated earlier, we can use the Kubernetes API to store data:

  - in the custom resources themselves

  - in other resources' annotations

---

## Beyond CRDs

- CRDs cannot use custom storage (e.g. for time series data)

- CRDs cannot support arbitrary subresources (like logs or exec for Pods)

- CRDs cannot support protobuf (for faster, more efficient communication)

- If we need these things, we can use the [aggregation layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) instead

- The aggregation layer proxies all requests below a specific path to another server

  (this is used e.g. by the metrics server)

- [This documentation page](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#choosing-a-method-for-adding-custom-resources) compares the features of CRDs and API aggregation

???

:EN:- Guidelines to design our own operators
:FR:- Comment concevoir nos propres opérateurs
