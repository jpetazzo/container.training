# Next steps

*Alright, how do I get started and containerize my apps?*

--

Suggested containerization checklist:

.checklist[
- write a Dockerfile for one service in one app
- write Dockerfiles for the other (buildable) services
- write a Compose file for that whole app
- make sure that devs are empowered to run the app in containers
- set up automated builds of container images from the code repo
- set up a CI pipeline using these container images
- set up a CD pipeline (for staging/QA) using these images
]

And *then* it is time to look at orchestration!

---

## Local workflow

- Make sure that you have a local Kubernetes cluster

  (Docker Desktop, Minikube, microk8s ...)

- Use that cluster early and often

- Regularly try to deploy on a "real" cluster

---

## Isolation

- We did *not* talk about Role-Based Access Control (RBAC)

- We did *not* talk about Network Policies
 
- We did *not* talk about Pod Security Policies

- We did *not* talk about resource limits, Limit Ranges, Resource Quotas

- You don't need these features when getting started

  (your friendly s19e team is here for that)

---

## Stateful services (databases etc.)

- As a first step, it is wiser to keep stateful services *outside* of the cluster

- Exposing them to pods can be done with multiple solutions:

  - `ExternalName` services
    <br/>
    (`redis.blue.svc.cluster.local` will be a `CNAME` record)

  - `ClusterIP` services with explicit `Endpoints`
    <br/>
    (instead of letting Kubernetes generate the endpoints from a selector)

  - Ambassador services
    <br/>
    (application-level proxies that can provide credentials injection and more)

---

## Stateful services (second take)

- If we want to host stateful services on Kubernetes, we can use:

  - a storage provider

  - persistent volumes, persistent volume claims

  - stateful sets

- Good questions to ask:

  - what's the *operational cost* of running this service ourselves?

  - what do we gain by deploying this stateful service on Kubernetes?

- Relevant sections:
  [Volumes](kube-selfpaced.yml.html#toc-volumes)
  |
  [Stateful Sets](kube-selfpaced.yml.html#toc-stateful-sets)
  |
  [Persistent Volumes](kube-selfpaced.yml.html#toc-highly-available-persistent-volumes)

- Excellent [blog post](http://www.databasesoup.com/2018/07/should-i-run-postgres-on-kubernetes.html) tackling the question: “Should I run Postgres on Kubernetes?”

---

## Developer experience

*We've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?

*Mind the gap!*