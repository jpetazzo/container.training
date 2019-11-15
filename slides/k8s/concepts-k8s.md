# Kubernetes concepts

- Kubernetes is a container management system

- It runs and manages containerized applications on a cluster

--

- What does that really mean?

---

## Basic things we can ask Kubernetes to do

--

- Start 5 containers using image `atseashop/api:v1.3`

--

- Place an internal load balancer in front of these containers

--

- Start 10 containers using image `atseashop/webfront:v1.3`

--

- Place a public load balancer in front of these containers

--

- It's Black Friday (or Christmas), traffic spikes, grow our cluster and add containers

--

- New release! Replace my containers with the new image `atseashop/webfront:v1.4`

--

- Keep processing requests during the upgrade; update my containers one at a time

---

## Other things that Kubernetes can do for us

- Autoscaling

  (straightforward on CPU; more complex on other metrics)

- Ressource management and scheduling

  (reserve CPU/RAM for containers; placement constraints)

- Advanced rollout patterns

  (blue/green deployment, canary deployment)

---

## More things that Kubernetes can do for us

- Batch jobs

  (one-off; parallel; also cron-style periodic execution)

- Fine-grained access control

  (defining *what* can be done by *whom* on *which* resources)

- Stateful services

  (databases, message queues, etc.)

- Automating complex tasks with *operators*

  (e.g. database replication, failover, etc.)

---

## Kubernetes architecture

---

class: pic

![haha only kidding](images/k8s-arch1.png)

---

## Kubernetes architecture

- Ha ha ha ha

- OK, I was trying to scare you, it's much simpler than that ❤️

---

class: pic

![that one is more like the real thing](images/k8s-arch2.png)

---

## Credits

- The first schema is a Kubernetes cluster with storage backed by multi-path iSCSI

  (Courtesy of [Yongbok Kim](https://www.yongbok.net/blog/))

- The second one is a simplified representation of a Kubernetes cluster

  (Courtesy of [Imesh Gunaratne](https://medium.com/containermind/a-reference-architecture-for-deploying-wso2-middleware-on-kubernetes-d4dee7601e8e))

---

## Kubernetes architecture: the nodes

- The nodes executing our containers run a collection of services:

  - a container Engine (typically Docker)

  - kubelet (the "node agent")

  - kube-proxy (a necessary but not sufficient network component)

- Nodes were formerly called "minions"

  (You might see that word in older articles or documentation)

---

## Kubernetes architecture: the control plane

- The Kubernetes logic (its "brains") is a collection of services:

  - the API server (our point of entry to everything!)

  - core services like the scheduler and controller manager

  - `etcd` (a highly available key/value store; the "database" of Kubernetes)

- Together, these services form the control plane of our cluster

- The control plane is also called the "master"

---

class: pic

![One of the best Kubernetes architecture diagrams available](images/k8s-arch4-thanks-luxas.png)

---

class: extra-details

## Running the control plane on special nodes

- It is common to reserve a dedicated node for the control plane

  (Except for single-node development clusters, like when using minikube)

- This node is then called a "master"

  (Yes, this is ambiguous: is the "master" a node, or the whole control plane?)

- Normal applications are restricted from running on this node

  (By using a mechanism called ["taints"](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/))

- When high availability is required, each service of the control plane must be resilient

- The control plane is then replicated on multiple nodes

  (This is sometimes called a "multi-master" setup)

---

class: extra-details

## Running the control plane outside containers

- The services of the control plane can run in or out of containers

- For instance: since `etcd` is a critical service, some people
  deploy it directly on a dedicated cluster (without containers)

  (This is illustrated on the first "super complicated" schema)

- In some hosted Kubernetes offerings (e.g. AKS, GKE, EKS), the control plane is invisible

  (We only "see" a Kubernetes API endpoint)

- In that case, there is no "master node"

*For this reason, it is more accurate to say "control plane" rather than "master."*

---

class: extra-details

## Do we need to run Docker at all?

No!

--

- By default, Kubernetes uses the Docker Engine to run containers

- We can leverage other pluggable runtimes through the *Container Runtime Interface*

- <del>We could also use `rkt` ("Rocket") from CoreOS</del> (deprecated)

---

class: extra-details

## Some runtimes available through CRI

- [containerd](https://github.com/containerd/containerd/blob/master/README.md)

  - maintained by Docker, IBM, and community
  - used by Docker Engine, microk8s, k3s, GKE; also standalone
  - comes with its own CLI, `ctr`

- [CRI-O](https://github.com/cri-o/cri-o/blob/master/README.md):

  - maintained by Red Hat, SUSE, and community
  - used by OpenShift and Kubic
  - designed specifically as a minimal runtime for Kubernetes

- [And more](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

---

class: extra-details

## Do we need to run Docker at all?

Yes!

--

- In this workshop, we run our app on a single node first

- We will need to build images and ship them around

- We can do these things without Docker
  <br/>
  (and get diagnosed with NIH¹ syndrome)

- Docker is still the most stable container engine today
  <br/>
  (but other options are maturing very quickly)

.footnote[¹[Not Invented Here](https://en.wikipedia.org/wiki/Not_invented_here)]

---

class: extra-details

## Do we need to run Docker at all?

- On our development environments, CI pipelines ... :

  *Yes, almost certainly*

- On our production servers:

  *Yes (today)*

  *Probably not (in the future)*

.footnote[More information about CRI [on the Kubernetes blog](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes)]

---

## Interacting with Kubernetes

- We will interact with our Kubernetes cluster through the Kubernetes API

- The Kubernetes API is (mostly) RESTful

- It allows us to create, read, update, delete *resources*

- A few common resource types are:

  - node (a machine — physical or virtual — in our cluster)

  - pod (group of containers running together on a node)

  - service (stable network endpoint to connect to one or multiple containers)

---

class: pic

![Node, pod, container](images/k8s-arch3-thanks-weave.png)

---

## Scaling

- How would we scale the pod shown on the previous slide?

- **Do** create additional pods

  - each pod can be on a different node

  - each pod will have its own IP address

- **Do not** add more NGINX containers in the pod

  - all the NGINX containers would be on the same node

  - they would all have the same IP address
    <br/>(resulting in `Address alreading in use` errors)

---

## Together or separate

- Should we put e.g. a web application server and a cache together?
  <br/>
  ("cache" being something like e.g. Memcached or Redis)

- Putting them **in the same pod** means:

  - they have to be scaled together

  - they can communicate very efficiently over `localhost`

- Putting them **in different pods** means:

  - they can be scaled separately

  - they must communicate over remote IP addresses
    <br/>(incurring more latency, lower performance)

- Both scenarios can make sense, depending on our goals

---

## Credits

- The first diagram is courtesy of Lucas Käldström, in [this presentation](https://speakerdeck.com/luxas/kubeadm-cluster-creation-internals-from-self-hosting-to-upgradability-and-ha)

  - it's one of the best Kubernetes architecture diagrams available!

- The second diagram is courtesy of Weave Works

  - a *pod* can have multiple containers working together

  - IP addresses are associated with *pods*, not with individual containers

Both diagrams used with permission.
