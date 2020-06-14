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

## One operator in action

- We will install [Elastic Cloud on Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html), an ElasticSearch operator

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

- The operator provides:

  - a few CustomResourceDefinitions
  - a Namespace for its other resources
  - a ValidatingWebhookConfiguration for type checking
  - a StatefulSet for its controller and webhook code
  - a ServiceAccount, ClusterRole, ClusterRoleBinding for permissions

- All these resources are grouped in a convenient YAML file

.exercise[

- Install the operator:
  ```bash
  kubectl apply -f ~/container.training/k8s/eck-operator.yaml
  ```

]

---

## Check our new custom resources

- Let's see which CRDs were created

.exercise[

- List all CRDs:
  ```bash
  kubectl get crds
  ```

]

This operator supports ElasticSearch, but also Kibana and APM. Cool!

---

## Create the `eck-demo` namespace

- For clarity, we will create everything in a new namespace, `eck-demo`

- This namespace is hard-coded in the YAML files that we are going to use

- We need to create that namespace

.exercise[

- Create the `eck-demo` namespace:
  ```bash
  kubectl create namespace eck-demo
  ```

- Switch to that namespace:
  ```bash
  kns eck-demo
  ```

]

---

class: extra-details

## Can we use a different namespace?

Yes, but then we need to update all the YAML manifests that we
are going to apply in the next slides.

The `eck-demo` namespace is hard-coded in these YAML manifests.

Why?

Because when defining a ClusterRoleBinding that references a
ServiceAccount, we have to indicate in which namespace the
ServiceAccount is located.

---

## Create an ElasticSearch resource

- We can now create a resource with `kind: ElasticSearch`

- The YAML for that resource will specify all the desired parameters:

  - how many nodes we want
  - image to use
  - add-ons (kibana, cerebro, ...)
  - whether to use TLS or not
  - etc.

.exercise[

- Create our ElasticSearch cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/eck-elasticsearch.yaml
  ```

]

---

## Operator in action

- Over the next minutes, the operator will create our ES cluster

- It will report our cluster status through the CRD

.exercise[

- Check the logs of the operator:
  ```bash
  stern --namespace=elastic-system operator
  ```

<!--
```wait elastic-operator-0```
```tmux split-pane -v```
--->

- Watch the status of the cluster through the CRD:
  ```bash
  kubectl get es -w
  ```

<!--
```longwait green```
```key ^C```
```key ^D```
```key ^C```
-->

]

---

## Connecting to our cluster

- It's not easy to use the ElasticSearch API from the shell

- But let's check at least if ElasticSearch is up!

.exercise[

- Get the ClusterIP of our ES instance:
  ```bash
  kubectl get services
  ```

- Issue a request with `curl`:
  ```bash
  curl http://`CLUSTERIP`:9200
  ```

]

We get an authentication error. Our cluster is protected!

---

## Obtaining the credentials

- The operator creates a user named `elastic`

- It generates a random password and stores it in a Secret

.exercise[

- Extract the password:
  ```bash
    kubectl get secret demo-es-elastic-user \
            -o go-template="{{ .data.elastic | base64decode }} "
  ```

- Use it to connect to the API:
  ```bash
  curl -u elastic:`PASSWORD` http://`CLUSTERIP`:9200
  ```

]

We should see a JSON payload with the `"You Know, for Search"` tagline.

---

## Sending data to the cluster

- Let's send some data to our brand new ElasticSearch cluster!

- We'll deploy a filebeat DaemonSet to collect node logs

.exercise[

- Deploy filebeat:
  ```bash
  kubectl apply -f ~/container.training/k8s/eck-filebeat.yaml
  ```

- Wait until some pods are up:
  ```bash
  watch kubectl get pods -l k8s-app=filebeat
  ```

<!--
```wait Running```
```key ^C```
-->

- Check that a filebeat index was created:
  ```bash
  curl -u elastic:`PASSWORD` http://`CLUSTERIP`:9200/_cat/indices
  ```

]

---

## Deploying an instance of Kibana

- Kibana can visualize the logs injected by filebeat

- The ECK operator can also manage Kibana

- Let's give it a try!

.exercise[

- Deploy a Kibana instance:
  ```bash
  kubectl apply -f ~/container.training/k8s/eck-kibana.yaml
  ```

- Wait for it to be ready:
  ```bash
  kubectl get kibana -w
  ```

<!--
```longwait green```
```key ^C```
-->

]

---

## Connecting to Kibana

- Kibana is automatically set up to conect to ElasticSearch

  (this is arranged by the YAML that we're using)

- However, it will ask for authentication

- It's using the same user/password as ElasticSearch

.exercise[

- Get the NodePort allocated to Kibana:
  ```bash
  kubectl get services
  ```

- Connect to it with a web browser

- Use the same user/password as before

]

---

## Setting up Kibana

After the Kibana UI loads, we need to click around a bit

.exercise[

- Pick "explore on my own"

- Click on Use Elasticsearch data / Connect to your Elasticsearch index"

- Enter `filebeat-*` for the index pattern and click "Next step"

- Select `@timestamp` as time filter field name

- Click on "discover" (the small icon looking like a compass on the left bar)

- Play around!

]

---

## Scaling up the cluster

- At this point, we have only one node

- We are going to scale up

- But first, we'll deploy Cerebro, an UI for ElasticSearch

- This will let us see the state of the cluster, how indexes are sharded, etc.

---

## Deploying Cerebro

- Cerebro is stateless, so it's fairly easy to deploy

  (one Deployment + one Service)

- However, it needs the address and credentials for ElasticSearch

- We prepared yet another manifest for that!

.exercise[

- Deploy Cerebro:
  ```bash
  kubectl apply -f ~/container.training/k8s/eck-cerebro.yaml
  ```

- Lookup the NodePort number and connect to it:
  ```bash
  kubectl get services
  ```

]

---

## Scaling up the cluster

- We can see on Cerebro that the cluster is "yellow"

  (because our index is not replicated)

- Let's change that!

.exercise[

- Edit the ElasticSearch cluster manifest:
  ```bash
  kubectl edit es demo
  ```

- Find the field `count: 1` and change it to 3

- Save and quit

<!--
```wait Please edit```
```keys /count:```
```key ^J```
```keys $r3:x```
```key ^J```
-->

]

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

- Look at the ElasticSearch resource definition

  (`~/container.training/k8s/eck-elasticsearch.yaml`)

- What should happen if we flip the TLS flag? Twice?

- What should happen if we add another group of nodes?

- What if we want different images or parameters for the different nodes?

*Operators can be very powerful.
<br/>
But we need to know exactly the scenarios that they can handle.*

???

:EN:- Kubernetes operators
:EN:- Deploying ElasticSearch with ECK

:FR:- Les opérateurs
:FR:- Déployer ElasticSearch avec ECK
