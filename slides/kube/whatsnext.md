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

- Metrics are typically handled with [Prometheus](https://prometheus.io/)

  ([Heapster](https://github.com/kubernetes/heapster) is a popular add-on)

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
