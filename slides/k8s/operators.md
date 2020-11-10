# Operators

*An operator represents **human operational knowledge in software,**
<br/>
to reliably manage an application.
— [CoreOS](https://coreos.com/blog/introducing-operators.html)*

Examples:

- Deploying and configuring replication with MySQL, PostgreSQL ...

- Setting up Elasticsearch, Kafka, RabbitMQ, Zookeeper ...

- Reacting to failures when intervention is needed

- Scaling up and down these systems

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

## Why use operators?

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

## Use-cases for operators

- Systems with primary/secondary replication

  Examples: MariaDB, MySQL, PostgreSQL, Redis ...

- Systems where different groups of nodes have different roles

  Examples: ElasticSearch, MongoDB ...

- Systems with complex dependencies (that are themselves managed with operators)

  Examples: Flink or Kafka, which both depend on Zookeeper

---

## More use-cases

- Representing and managing external resources

  (Example: [AWS S3 Operator](https://operatorhub.io/operator/awss3-operator-registry))

- Managing complex cluster add-ons

  (Example: [Istio operator](https://operatorhub.io/operator/istio))

- Deploying and managing our applications' lifecycles

  (more on that later)

---

## How operators work

- An operator creates one or more CRDs

  (i.e., it creates new "Kinds" of resources on our cluster)

- The operator also runs a *controller* that will watch its resources

- Each time we create/update/delete a resource, the controller is notified

  (we could write our own cheap controller with `kubectl get --watch`)

---

## Deploying our apps with operators

- It is very simple to deploy with `kubectl create deployment` / `kubectl expose`

- We can unlock more features by writing YAML and using `kubectl apply`

- Kustomize or Helm let us deploy in multiple environments

  (and adjust/tweak parameters in each environment)

- We can also use an operator to deploy our application

---

## Pros and cons of deploying with operators

- The app definition and configuration is persisted in the Kubernetes API

- Multiple instances of the app can be manipulated with `kubectl get`

- We can add labels, annotations to the app instances

- Our controller can execute custom code for any lifecycle event

- However, we need to write this controller

- We need to be careful about changes

  (what happens when the resource `spec` is updated?)

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
