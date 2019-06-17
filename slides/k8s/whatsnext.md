# Next steps

- One day is not a lot of time to learn everything about Kubernetes

- Here is a short list of things you might want to look at later ...

---

## Namespaces

- Namespaces let you run multiple identical stacks side by side

- Two namespaces (e.g. `blue` and `green`) can each have their own `redis` service

- Each of the two `redis` services has its own `ClusterIP`

- CoreDNS creates two entries, mapping to these two `ClusterIP` addresses:

  `redis.blue.svc.cluster.local` and `redis.green.svc.cluster.local`

- Pods in the `blue` namespace get a *search suffix* of `blue.svc.cluster.local`

- As a result, resolving `redis` from a pod in the `blue` namespace yields the "local" `redis`

.warning[This does not provide *isolation*! That would be the job of network policies.]

---

## Relevant sections

- [Namespaces](kube-selfpaced.yml.html#toc-namespaces)

- [Network Policies](kube-selfpaced.yml.html#toc-network-policies)

- [Role-Based Access Control](kube-selfpaced.yml.html#toc-authentication-and-authorization)

  (covers permissions model, user and service accounts management ...)

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

## HTTP traffic handling

- *Services* are layer 4 constructs

- HTTP is a layer 7 protocol

- It is handled by *ingresses* (a different resource kind)

- *Ingresses* allow:

  - virtual host routing
  - session stickiness
  - URI mapping
  - and much more!

- [This section](kube-selfpaced.yml.html#toc-exposing-http-services-with-ingress-resources) shows how to expose multiple HTTP apps using [Træfik](https://docs.traefik.io/user-guide/kubernetes/)

---

## Managing the configuration of our applications

- Two constructs are particularly useful: secrets and config maps

- They allow to expose arbitrary information to our containers

- **Avoid** storing configuration in container images

  (There are some exceptions to that rule, but it's generally a Bad Idea)

- **Never** store sensitive information in container images

  (It's the container equivalent of the password on a post-it note on your screen)

- [This section](kube-selfpaced.yml.html#toc-managing-configuration) shows how to manage app config with config maps (among others)

---

## And everything else

- Congratulations!

- We learned a lot about Kubernetes

--

- That was just the easy part

- The hard challenges will revolve around *culture* and *people*

--

- ... What does that mean?

---

## Running an app involves many steps

- Write the app

- Tests, QA ...

- Ship *something* (more on that later)

- Provision resources (e.g. VMs, clusters)

- Deploy the *something* on the resources

- Manage, maintain, monitor the resources

- Manage, maintain, monitor the app

- And much more

---

## Who does what?

- The old "devs vs ops" division has changed

- In some organizations, "ops" are now called "SRE" or "platform" teams

  (and they have very different sets of skills)

- Do you know which team is responsible for each item on the list on the previous page?

- Acknowledge that a lot of tasks are outsourced

  (e.g. if we add "buy/rack/provision machines" in that list)

---

## What do we ship?

- Some organizations embrace "you build it, you run it"

- When "build" and "run" are owned by different teams, where's the line?

- What does the "build" team ship to the "run" team?

- Let's see a few options, and what they imply

---

## Shipping code

- Team "build" ships code

  (hopefully in a repository, identified by a commit hash)

- Team "run" containerizes that code

✔️ no extra work for developers

❌ very little advantage of using containers

---

## Shipping container images

- Team "build" ships container images

  (hopefully built automatically from a source repository)

- Team "run" uses theses images to create e.g. Kubernetes resources

✔️ universal artefact (support all languages uniformly)

✔️ easy to start a single component (good for monoliths)

❌ complex applications will require a lot of extra work

❌ adding/removing components in the stack also requires extra work

❌ complex applications will run very differently between dev and prod

---

## Shipping Compose files

(Or another kind of dev-centric manifest)

- Team "build" ships a manifest that works on a single node

  (as well as images, or ways to build them)

- Team "run" adapts that manifest to work on a cluster

✔️ all teams can start the stack in a reliable, deterministic manner

❌ adding/removing components still requires *some* work (but less than before)

❌ there will be *some* differences between dev and prod

---

## Shipping Kubernetes manifests

- Team "build" ships ready-to-run manifests

  (YAML, Helm charts, Kustomize ...)

- Team "run" adjusts some parameters and monitors the application

✔️ parity between dev and prod environments

✔️ "run" team can focus on SLAs, SLOs, and overall quality

❌ requires *a lot* of extra work (and new skills) from the "build" team

❌ Kubernetes is not a very convenient development platform (at least, not yet)

---

## What's the right answer?

- It depends on our teams

  - existing skills (do they know how to do it?)

  - availability (do they have the time to do it?)

  - potential skills (can they learn to do it?)

- It depends on our culture

  - owning "run" often implies being on call

  - do we reward on-call duty without encouraging hero syndrome?

  - do we give people resources (time, money) to learn?

---

## Some guidelines

- Start small

- Outsource what we don't know

- Start simple, and stay simple as long as possible

  (try to stay away from complex features that we don't need)

- Automate

  (regularly check that we can successfully redeploy by following scripts)

- Transfer knowledge

  (make sure everyone is on the same page/level)

- Iterate!

---

## Where do we start?

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

## Options for our first production cluster

- Get a managed cluster from a major cloud provider (AKS, EKS, GKE...)

  (price: $, difficulty: medium)

- Hire someone to deploy it for us

  (price: $$, difficulty: easy)

- Do it ourselves

  (price: $-$$$, difficulty: hard)

---

## One big cluster vs. multiple small ones

- Yes, it is possible to have prod+dev in a single cluster

  (and implement good isolation and security with RBAC, network policies...)

- But it is not a good idea to do that for our first deployment

- Start with a production cluster + at least a test cluster

- Implement and check RBAC and isolation on the test cluster

  (e.g. deploy multiple test versions side-by-side)

- Make sure that all our devs have usable dev clusters

  (whether it's a local minikube or a full-blown multi-node cluster)

---

## Developer experience

*We've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?
