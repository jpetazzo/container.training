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
  - [Brigade](https://brigade.sh/) (event-driven scripting; no YAML)

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

- etcd uses the [Raft](https://raft.github.io/) protocol

- Raft recommends low latency between nodes

- What if our cluster spreads to multiple regions?

--

- Break it down in local clusters

- Regroup them in a *cluster federation*

- Synchronize resources across clusters

- Discover resources across clusters

---

## Developer experience

*We've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?
