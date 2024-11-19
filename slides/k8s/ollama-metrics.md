# Adding metrics

We want multiple kinds of metrics:

- instantaneous pod and node resource usage

- historical resource usage (=graphs)

- request duration

---

## 1️⃣ Instantaneous resource usage

- We're going to use metrics-server

- Check if it's already installed:
  ```bash
  kubectl top nodes
  ```

- If we see a list of nodes, with CPU and RAM usage:

  *great, metrics-server is installed!*

- If we see `error: Metrics API not available`:

  *metrics-server isn't installed, so we'll install it!*

---

## Installing metrics-server

- In a lot of places, this is done with a little bit of custom YAML

  (derived from the [official installation instructions](https://github.com/kubernetes-sigs/metrics-server#installation))

- We can also use a Helm chart:
  ```bash
    helm upgrade --install metrics-server metrics-server \
      --create-namespace --namespace metrics-server \
      --repo https://kubernetes-sigs.github.io/metrics-server/ \
      --set args={--kubelet-insecure-tls=true}
  ```

- The `args` flag specified above should be sufficient on most clusters

- After a minute, `kubectl top nodes` should show resource usage

---

## 2️⃣ Historical resource usage

- We're going to use Prometheus (specifically: kube-prometheus-stack)

- This is a Helm chart bundling:

  - Prometheus

  - multiple exporters (node, kube-state-metrics...)

  - Grafana

  - a handful of Grafana dashboards

- Open Source

- Commercial alternatives: Datadog, New Relic...

---

## Installing kube-prometheus-stack

We're going to expose both Prometheus and Grafana with a NodePort:

```bash
helm upgrade --install --repo https://prometheus-community.github.io/helm-charts \
  promstack kube-prometheus-stack \
  --namespace prom-system --create-namespace \
  --set prometheus.service.type=NodePort \
  --set grafana.service.type=NodePort \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  #
```

This chart installation can take a while (up to a couple of minutes).

---

class: extra-details

## `...NilUsersHelmValues=false` ???

- kube-prometheus-stack uses the "Prometheus Operator"

- To configure "scrape targets", we create PodMonitor or ServiceMonitor resources

- By default, the Prometheus Operator will only look at \*Monitors with the right labels

- Our extra options mean "use all the Monitors that you will find!"

---

## Connecting to Grafana

Check the NodePort allocated to Grafana:

```bash
kubectl get service promstack-grafana --namespace prom-system
```

Get the public address of one of our nodes:

```bash
kubectl get nodes -o wide
```

Connect to the public address of a node, on the node port.

The default login and password are `admin` / `prom-operator`.

Check the dashboard "Kubernetes / Compute Resources / Namespace (Pods)".

Select a namespace and see the CPU and RAM usage for the pods in that namespace.

---

## 3️⃣ Request duration

- Unfortunately, as of November 2024, ollama doesn't expose metrics

  (there is ongoing discussion about it: [issue 3144][3144], [PR 6537][6537])

- There are some [garbage AI-generated blog posts claiming otherwise][garbage]

  (but it's AI-generated, so it bears no connection to truth whatsoever)

- So, what can we do?

[3144]: https://github.com/ollama/ollama/issues/3144#issuecomment-2153184254
[6537]: https://github.com/ollama/ollama/pull/6537
[garbage]: https://www.arsturn.com/blog/setting-up-ollama-prometheus-metrics

---

## HAProxy to the rescue

- HAProxy is a proxy that can handle TCP, HTTP, and more

- It can expose detailed Prometheus metrics about HTTP requests

- The plan: add a sidecar HAProxy to each Ollama container

- For that, we need to give up on the Ollama Helm chart

  (and go back to basic manifests)

---

## 🙋 Choose your adventure

Do we want to...

- write all the corresponding manifests?

- look at pre-written manifests and explain how they work?

- apply the manifests and carry on?

---

## 🏗️ Let's build something!

- If you have created Deployments / Services: clean them up first!

- Deploy Ollama with a sidecar HAProxy (sample configuration on next slide)

- Run a short benchmark campaign

  (e.g. scale to 4 pods, try 4/8/16 parallel requests, 2 minutes each)

- Check live resource usage with `kubectl top nodes` / `kubectl top pods`

- Check historical usage with the Grafana dashboards

  (for HAProxy metrics, you can use [Grafana dashboard 12693, HAProxy 2 Full][grafana-12693])

- If you don't want to write the manifests, you can use [these ones][ollama-yaml]

[grafana-12693]: https://grafana.com/grafana/dashboards/12693-haproxy-2-full/
[ollama-yaml]: https://github.com/jpetazzo/beyond-load-balancers/tree/main/ollama

---

```
global
  #log stdout format raw local0
  #daemon
  maxconn 32
defaults
  #log global
  timeout client 1h
  timeout connect 1h
  timeout server 1h
  mode http
  `option abortonclose`
frontend metrics
  bind :9000
  http-request use-service prometheus-exporter
frontend ollama_frontend
  bind :8000
  default_backend ollama_backend
  `maxconn 16`
backend ollama_backend
  server ollama_server localhost:11434 check
```

---

class: extra-details

## ⚠️ Connection queues

- HAProxy will happily queue *many* connections

- If a client sends a request, then disconnects:

  - the request stays in the queue

  - the request gets processed by the backend

  - eventually, when the backend starts sending the reply, the connection is closed

- This can result in a backlog of queries that take a long time to resorb

- To avoid that: `option abortonclose` (see [HAProxy docs for details][abortonclose])

- Note that the issue is less severe when replies are streamed

[abortonclose]: https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/#4-option%20abortonclose

---

class: extra-details

## Ad-hoc HAProxy dashboard

- To consolidate all frontend and backend queues on a single graph:

  - query: `haproxy_frontend_current_sessions`

  - legend: `{{namespace}}/{{pod}}/{{proxy}}`

  - options, "Color scheme", select "Classic palette (by series name)"

---

## What do we see?

- Imperfect load balancing

- Some backends receive more requests than others

- Sometimes, some backends are idle while others are busy

- However, CPU utilization on the node is maxed out

- This is because our node is oversubscribed

- This is because we didn't specify of resource requests/limits (yet)

  (we'll do that later!)
