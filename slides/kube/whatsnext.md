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

## Namespaces

- Namespaces let you run multiple identical stacks side by side

- Two namespaces (e.g. `blue` and `green`) can each have their own `redis` service

- Each of the two `redis` services has its own `ClusterIP`

- `kube-dns` creates two entries, mapping to these two `ClusterIP` addresses:

  `redis.blue.svc.cluster.local` and `redis.green.svc.cluster.local`

- Pods in the `blue` namespace get a *search suffix* of `blue.svc.cluster.local`

- As a result, resolving `redis` from a pod in the `blue` namespace yields the "local" `redis`

.warning[This does not provide *isolation*! That would be the job of network policies.]

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

- If you really want to host stateful services on Kubernetes, you can look into:

  - volumes (to carry persistent data)

  - storage plugins

  - persistent volume claims (to ask for specific volume characteristics)

  - stateful sets (pods that are *not* ephemeral)

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

- Check out e.g. [Træfik](https://docs.traefik.io/user-guide/kubernetes/)

---

## Logging and metrics

- Logging is delegated to the container engine

- Metrics are typically handled with Prometheus

  (Heapster is a popular add-on)

---

## Managing the configuration of our applications

- Two constructs are particularly useful: secrets and config maps

- They allow to expose arbitrary information to our containers

- **Avoid** storing configuration in container images

  (There are some exceptions to that rule, but it's generally a Bad Idea)

- **Never** store sensitive information in container images

  (It's the container equivalent of the password on a post-it note on your screen)

---

## Managing stack deployments

- The best deployment tool will vary, depending on:

  - the size and complexity of your stack(s)
  - how often you change it (i.e. add/remove components)
  - the size and skills of your team

- A few examples:

  - shell scripts invoking `kubectl`
  - YAML resources descriptions committed to a repo
  - [Helm](https://github.com/kubernetes/helm) (~package manager)
  - [Spinnaker](https://www.spinnaker.io/) (Netflix' CD platform)

---

## Cluster federation

--

![Star Trek Federation](images/startrek-federation.jpg)

--

Sorry Star Trek fans, this is not the federation you're looking for!

--

(If I add "Your cluster is in another federation" I might get a 3rd fandom wincing!)

---

## Cluster federation

- Kubernetes master operation relies on etcd

- etcd uses the Raft protocol

- Raft recommends low latency between nodes

- What if our cluster spreads multiple regions?

--

- Break it down in local clusters

- Regroup them in a *cluster federation*

- Synchronize resources across clusters

- Discover resources across clusters

---

## Developer experience

*I've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?
