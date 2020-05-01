# API server availability

- When we set up a node, we need the address of the API server:

  - for kubelet

  - for kube-proxy

  - sometimes for the pod network system (like kube-router)

- How do we ensure the availability of that endpoint?

  (what if the node running the API server goes down?)

---

## Option 1: external load balancer

- Set up an external load balancer

- Point kubelet (and other components) to that load balancer

- Put the node(s) running the API server behind that load balancer

- Update the load balancer if/when an API server node needs to be replaced

- On cloud infrastructures, some mechanisms provide automation for this

  (e.g. on AWS, an Elastic Load Balancer + Auto Scaling Group)

- [Example in Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#the-kubernetes-frontend-load-balancer)

---

## Option 2: local load balancer

- Set up a load balancer (like NGINX, HAProxy...) on *each* node

- Configure that load balancer to send traffic to the API server node(s)

- Point kubelet (and other components) to `localhost`

- Update the load balancer configuration when API server nodes are updated

---

## Updating the local load balancer config

- Distribute the updated configuration (push)

- Or regularly check for updates (pull)

- The latter requires an external, highly available store
 
  (it could be an object store, an HTTP server, or even DNS...)

- Updates can be facilitated by a DaemonSet

  (but remember that it can't be used when installing a new node!)

---

## Option 3: DNS records

- Put all the API server nodes behind a round-robin DNS

- Point kubelet (and other components) to that name

- Update the records when needed

- Note: this option is not officially supported

  (but since kubelet supports reconnection anyway, it *should* work)

---

## Option 4: ....................

- Many managed clusters expose a high-availability API endpoint

  (and you don't have to worry about it)

- You can also use HA mechanisms that you're familiar with

  (e.g. virtual IPs)

- Tunnels are also fine

  (e.g. [k3s](https://k3s.io/) uses a tunnel to allow each node to contact the API server)

???

:EN:- Ensuring API server availability
:FR:- Assurer la disponibilité du serveur API
