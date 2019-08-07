# Operators

- Operators are one of the many ways to extend Kubernetes

- We will define operators

- We will see how they work

- We will install a specific operator (for ElasticSearch)

- We will use it to provision an ElasticSearch cluster

---

## What are operators?

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

  (Example: [AWS Service Operator](https://operatorhub.io/operator/alpha/aws-service-operator.v0.0.1))

- Managing complex cluster add-ons

  (Example: [Istio operator](https://operatorhub.io/operator/beta/istio-operator.0.1.6))

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

## One operator in action

- We will install the UPMC Enterprises ElasticSearch operator

- This operator requires PersistentVolumes

- We will install Rancher's [local path storage provisioner](https://github.com/rancher/local-path-provisioner) to automatically create these

- Then, we will create an ElasticSearch resource

- The operator will detect that resource and provision the cluster

---

## Installing a Persistent Volume provisioner

(This step can be skipped if you already have a dynamic volume provisioner.)

- This provisioner creates Persistent Volumes backed by `hostPath`

  (local directories on our nodes)

- It doesn't require anything special ...

- ... But losing a node = losing the volumes on that node!

.exercise[

- Install the local path storage provisioner:
  ```bash
  kubectl apply -f ~/container.training/k8s/local-path-storage.yaml
  ```

]

---

## Making sure we have a default StorageClass

- The ElasticSearch operator will create StatefulSets

- These StatefulSets will instantiate PersistentVolumeClaims

- These PVCs need to be explicitly associated with a StorageClass

- Or we need to tag a StorageClass to be used as the default one

.exercise[

- List StorageClasses:
  ```bash
  kubectl get storageclasses
  ```

]

We should see the `local-path` StorageClass.

---

## Setting a default StorageClass

- This is done by adding an annotation to the StorageClass:

  `storageclass.kubernetes.io/is-default-class: true`

.exercise[

- Tag the StorageClass so that it's the default one:
  ```bash
  kubectl annotate storageclass local-path \
            storageclass.kubernetes.io/is-default-class=true
  ```

- Check the result:
  ```bash
  kubectl get storageclasses
  ```

]

Now, the StorageClass should have `(default)` next to its name.

---

## Install the ElasticSearch operator

- The operator needs:

  - a Deployment for its controller
  - a ServiceAccount, ClusterRole, ClusterRoleBinding for permissions
  - a Namespace

- We have grouped all the definitions for these resources in a YAML file

.exercise[

- Install the operator:
  ```bash
  kubectl apply -f ~/container.training/k8s/elasticsearch-operator.yaml
  ```

]

---

## Wait for the operator to be ready

- Some operators require to create their CRDs separately

- This operator will create its CRD itself

  (i.e. the CRD is not listed in the YAML that we applied earlier)

.exercise[

- Wait until the `elasticsearchclusters` CRD shows up:
  ```bash
  kubectl get crds
  ```

]

---

## Create an ElasticSearch resource

- We can now create a resource with `kind: ElasticsearchCluster`

- The YAML for that resource will specify all the desired parameters:

  - how many nodes do we want of each type (client, master, data)
  - image to use
  - add-ons (kibana, cerebro, ...)
  - whether to use TLS or not
  - etc.

.exercise[

- Create our ElasticSearch cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/elasticsearch-cluster.yaml
  ```

]

---

## Operator in action

- Over the next minutes, the operator will create:

  - StatefulSets (one for master nodes, one for data nodes)

  - Deployments (for client nodes; and for add-ons like cerebro and kibana)

  - Services (for all these pods)

.exercise[

- Wait for all the StatefulSets to be fully up and running:
  ```bash
  kubectl get statefulsets -w
  ```

]

---

## Connecting to our cluster

- Since connecting directly to the ElasticSearch API is a bit raw,
  <br/>we'll connect to the cerebro frontend instead

.exercise[

- Edit the cerebro service to change its type from ClusterIP to NodePort:
  ```bash
  kubectl patch svc cerebro-es -p "spec: { type: NodePort }"
  ```

- Retrieve the NodePort that was allocated:
  ```bash
  kubectl get svc cerebro-es
  ```

- Connect to that port with a browser

]

---

## (Bonus) Setup filebeat

- Let's send some data to our brand new ElasticSearch cluster!

- We'll deploy a filebeat DaemonSet to collect node logs

.exercise[

- Deploy filebeat:
  ```bash
  kubectl apply -f ~/container.training/k8s/filebeat.yaml
  ```

]

We should see at least one index being created in cerebro.

---

## (Bonus) Access log data with kibana

- Let's expose kibana (by making kibana-es a NodePort too)

- Then access kibana

- We'll need to configure kibana indexes

---

## Deploying our apps with operators

- It is very simple to deploy with `kubectl run` / `kubectl expose`

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

- Look at the ElasticSearch resource definition

  (`~/container.training/k8s/elasticsearch-cluster.yaml`)

- What should happen if we flip the `use-tls` flag? Twice?

- What should happen if we remove / re-add the kibana or cerebro sections?

- What should happen if we change the number of nodes?

- What if we want different images or parameters for the different nodes?

*Operators can be very powerful.
<br/>
But we need to know exactly the scenarios that they can handle.*
