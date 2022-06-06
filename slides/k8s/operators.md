# Operators

The Kubernetes documentation describes the [Operator pattern] as follows:

*Operators are software extensions to Kubernetes that make use of custom resources to manage applications and their components. Operators follow Kubernetes principles, notably the control loop.*

Another good definition from [CoreOS](https://coreos.com/blog/introducing-operators.html):

*An operator represents **human operational knowledge in software,**
<br/>
to reliably manage an application.*

There are many different use cases spanning different domains; but the general idea is:

*Manage some resources (that reside inside our outside the cluster),
<br/>
using Kubernetes manifests and tooling.*

[Operator pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/

---

## Some uses cases

- Managing external resources ([AWS], [GCP], [KubeVirt]...)

- Setting up database replication or distributed systems
  <br/>
  (Cassandra, Consul, CouchDB, ElasticSearch, etcd, Kafka, MongoDB, MySQL, PostgreSQL, RabbitMQ, Redis, ZooKeeper...)

- Running and configuring CI/CD
  <br/>
  ([ArgoCD], [Flux]), backups ([Velero]), policies ([Gatekeeper], [Kyverno])...

- Automating management of certificates and secrets
  <br/>
  ([cert-manager]), secrets ([External Secrets Operator], [Sealed Secrets]...)

- Configuration of cluster components ([Istio], [Prometheus])

- etc.

[ArgoCD]: https://github.com/argoproj/argo-cd
[AWS]: https://aws-controllers-k8s.github.io/community/docs/community/services/
[cert-manager]: https://cert-manager.io/
[External Secrets Operator]: https://external-secrets.io/
[Flux]: https://fluxcd.io/
[Gatekeeper]: https://open-policy-agent.github.io/gatekeeper/website/docs/
[GCP]: https://github.com/paulczar/gcp-cloud-compute-operator
[Istio]: https://istio.io/latest/docs/setup/install/operator/
[KubeVirt]: https://kubevirt.io/
[Kyverno]: https://kyverno.io/
[Prometheus]: https://prometheus-operator.dev/
[Sealed Secrets]: https://github.com/bitnami-labs/sealed-secrets
[Velero]: https://velero.io/

---

## What are they made from?

- Operators combine two things:

  - Custom Resource Definitions

  - controller code watching the corresponding resources and acting upon them

- A given operator can define one or multiple CRDs

- The controller code (control loop) typically runs within the cluster

  (running as a Deployment with 1 replica is a common scenario)

- But it could also run elsewhere

  (nothing mandates that the code run on the cluster, as long as it has API access)

---

## Operators for e.g. replicated databases

- Kubernetes gives us Deployments, StatefulSets, Services ...

- These mechanisms give us building blocks to deploy applications

- They work great for services that are made of *N* identical containers

  (like stateless ones)

- They also work great for some stateful applications like Consul, etcd ...

  (with the help of highly persistent volumes)

- They're not enough for complex services:

  - where different containers have different roles

  - where extra steps have to be taken when scaling or replacing containers

---

## How operators work

- An operator creates one or more CRDs

  (i.e., it creates new "Kinds" of resources on our cluster)

- The operator also runs a *controller* that will watch its resources

- Each time we create/update/delete a resource, the controller is notified

  (we could write our own cheap controller with `kubectl get --watch`)

---

## Operators are not magic

- Look at this ElasticSearch resource definition:

  @@LINK[k8s/eck-elasticsearch.yaml]

- What should happen if we flip the TLS flag? Twice?

- What should happen if we add another group of nodes?

- What if we want different images or parameters for the different nodes?

*Operators can be very powerful.
<br/>
But we need to know exactly the scenarios that they can handle.*

???

:EN:- Kubernetes operators
:FR:- Les opérateurs
