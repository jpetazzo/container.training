class: title, talk-only

What's missing?

---

## What's missing?

- Mostly: security

- Notably: RBAC

- Also: availabilty

---

## TLS! TLS everywhere!

- Create certs for the control plane:

  - etcd

  - API server

  - controller manager

  - scheduler

- Create individual certs for nodes

- Create the service account key pair

---

## Service accounts

- The controller manager will generate tokens for service accounts

  (these tokens are JWT, JSON Web Tokens, signed with a specific key)

- The API server will validate these tokens (with the matching key)

---

## Nodes

- Enable NodeRestriction admission controller

  - authorizes kubelet to update their own node and pods data

- Enable Node Authorizer

  - prevents kubelets from accessing data that they shouldn't

  - only authorize access to e.g. a configmap if a pod is using it

- Bootstrap tokens

  - add nodes to the cluster safely+dynamically

---

## Consequences of API server outage

- What happens if the API server goes down?

  - kubelet will try to reconnect (as long as necessary)

  - our apps will be just fine (but autoscaling will be broken)

- How can we improve the API server availability?

  - redundancy (the API server is stateless)

  - achieve a low MTTR

---

## Improving API server availability

- Redundancy implies to add one layer

  (between API clients and servers)

- Multiple options available:

  - external load balancer

  - local load balancer (NGINX, HAProxy... on each node)

  - DNS Round-Robin

---

## Achieving a low MTTR

- Run the control plane in highly available VMs

  (e.g. many hypervisors can do that, with shared or mirrored storage)

- Run the control plane in highly available containers

  (e.g. on another Kubernetes cluster)

---

class: title

Thank you!

---

## A word from my sponsor

- If you liked this presentation and would like me to train your team ...

  Contact me: jerome.petazzoni@gmail.com

- Thank you! ♥️

- Also, slides👇🏻

![QR code to the slides](images/qrcode-lisa.png)





