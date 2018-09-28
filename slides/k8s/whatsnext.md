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

*I've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?
