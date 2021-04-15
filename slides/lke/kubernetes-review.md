# Quick Kubernetes review

- Let's deploy a simple HTTP server

- And expose it to the outside world!

- Feel free to skip this section if you're familiar with Kubernetes

---

## Creating a container

- On Kubernetes, one doesn't simply run a container

- We need to create a "Pod"

- A Pod will be a group of containers running together

  (often, it will be a group of *one* container)

- We can create a standalone Pod, but generally, we'll use a *controller*

  (for instance: Deployment, Replica Set, Daemon Set, Job, Stateful Set...)

- The *controller* will take care of scaling and recreating the Pod if needed

  (note that within a Pod, containers can also be restarted automatically if needed)

---

## A *controller*, you said?

- We're going to use one of the most common controllers: a *Deployment*

- Deployments...

  - can be scaled (will create the requested number of Pods)

  - will recreate Pods if e.g. they get evicted or their Node is down

  - handle rolling updates

- Deployments actually delegate a lot of these tasks to *Replica Sets*

- We will generally have the following hierarchy:
 
  Deployment → Replica Set → Pod

---

## Creating a Deployment

- Without further ado:
  ```bash
  kubectl create deployment web --image=nginx
  ```

- Check what happened:
  ```bash
  kubectl get all
  ```

- Wait until the NGINX Pod is "Running"!

- Note: `kubectl create deployment` is great when getting started...

- ... But later, we will probably write YAML instead!

---

## Exposing the Deployment

- We need to create a Service

- We can use `kubectl expose` for that

  (but, again, we will probably use YAML later!)

- For *internal* use, we can use the default Service type, ClusterIP:
  ```bash
  kubectl expose deployment web --port=80
  ```

- For *external* use, we can use a Service of type LoadBalancer:
  ```bash
  kubectl expose deployment web --port=80 --type=LoadBalancer
  ```

---

## Changing the Service type

- We can `kubectl delete service web` and recreate it

- Or, `kubectl edit service web` and dive into the YAML

- Or, `kubectl patch service web --patch '{"spec": {"type": "LoadBalancer"}}'`

- ... These are just a few "classic" methods; there are many ways to do this!

---

## Deployment → Pod

- Can we check exactly what's going on when the Pod is created?

- Option 1: `watch kubectl get all`

  - displays all object types
  - refreshes every 2 seconds
  - puts a high load on the API server when there are many objects

- Option 2: `kubectl get pods --watch --output-watch-events`

  - can only display one type of object
  - will show all modifications happening (à la `tail -f`)
  - doesn't put a high load on the API server (except for initial display)

---

## Recreating the Deployment

- Let's delete our Deployment:
  ```bash
  kubectl delete deployment web
  ```

- Watch Pod updates:
  ```bash
  kubectl get pods --watch --output-watch-events
  ```

- Recreate the Deployment and see what Pods do:
  ```bash
  kubectl create deployment web --image=nginx
  ```

---

## Service stability

- Our Service *still works* even though we deleted and re-created the Deployment

- It wouldn't have worked while the Deployment was deleted, though

- A Service is a *stable endpoint*

???

:T: Warming up with a quick Kubernetes review

:Q: In Kubernetes, what is a Pod?
:A: ✔️A basic unit of scaling that can contain one or more containers
:A: An abstraction for an application and its dependencies
:A: It's just a fancy name for "container" but they're the same
:A: A group of cluster nodes used for scheduling purposes

:Q: In Kubernetes, what is a Replica Set?
:A: ✔️A controller used to create one or multiple identical Pods
:A: A numeric parameter in a Pod specification, used to scale that Pod
:A: A group of containers running on the same node
:A: A group of containers running on different nodes

:Q: In Kubernetes, what is a Deployment?
:A: ✔️A controller that can manage Replica Sets corresponding to different configurations
:A: A manifest telling Kubernetes how to deploy an app and its dependencies
:A: A list of instructions executed in a container to configure that container
:A: A basic unit of work for the Kubernetes scheduler
