# Checking Node and Pod resource usage

- We've installed a few things on our cluster so far

- How much resources (CPU, RAM) are we using?

- We need metrics!

.lab[

- Let's try the following command:
  ```bash
  kubectl top nodes
  ```
]

---

## Is metrics-server installed?

- If we see a list of nodes, with CPU and RAM usage:

  *great, metrics-server is installed!*

- If we see `error: Metrics API not available`:

  *metrics-server isn't installed, so we'll install it!*

---

## The resource metrics pipeline

- The `kubectl top` command relies on the Metrics API

- The Metrics API is part of the "[resource metrics pipeline]"

- The Metrics API isn't served (built into) the Kubernetes API server

- It is made available through the [aggregation layer]

- It is usually served by a component called metrics-server

- It is optional (Kubernetes can function without it)

- It is necessary for some features (like the Horizontal Pod Autoscaler)

[resource metrics pipeline]: https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/
[aggregation layer]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/

---

## Other ways to get metrics

- We could use a SAAS like Datadog, New Relic...

- We could use a self-hosted solution like Prometheus

- Or we could use metrics-server

- What's special about metrics-server?

---

## Pros/cons

Cons:

- no data retention (no history data, just instant numbers)

- only CPU and RAM of nodes and pods (no disk or network usage or I/O...)

Pros:

- very lightweight

- doesn't require storage

- used by Kubernetes autoscaling

---

## Why metrics-server

- We may install something fancier later

  (think: Prometheus with Grafana)

- But metrics-server will work in *minutes*

- It will barely use resources on our cluster

- It's required for autoscaling anyway

---

## How metric-server works

- It runs a single Pod

- That Pod will fetch metrics from all our Nodes

- It will expose them through the Kubernetes API aggregation layer

  (we won't say much more about that aggregation layer; that's fairly advanced stuff!)

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

---

class: extra-details

## Kubelet insecure TLS?

- The metrics-server collects metrics by connecting to kubelet

- The connection is secured by TLS

- This requires a valid certificate

- In some cases, the certificate is self-signed

- In other cases, it might be valid, but include only the node name

  (not its IP address, which is used by default by metrics-server)

---

## Testing metrics-server

- After a minute or two, metrics-server should be up

- We should now be able to check Nodes resource usage:
  ```bash
  kubectl top nodes
  ```

- And Pods resource usage, too:
  ```bash
  kubectl top pods --all-namespaces
  ```

---

## Keep some padding

- The RAM usage that we see should correspond more or less to the Resident Set Size

- Our pods also need some extra space for buffers, caches...

- Do not aim for 100% memory usage!

- Some more realistic targets:

  50% (for workloads with disk I/O and leveraging caching)

  90% (on very big nodes with mostly CPU-bound workloads)

  75% (anywhere in between!)

---

## Other tools

- kube-capacity is a great CLI tool to view resources

  (https://github.com/robscott/kube-capacity)

- It can show resource and limits, and compare them with usage

- It can show utilization per node, or per pod

- kube-resource-report can generate HTML reports

  (https://codeberg.org/hjacobs/kube-resource-report)

???

:EN:- The resource metrics pipeline
:EN:- Installing metrics-server

:EN:- Le *resource metrics pipeline*
:FR:- Installtion de metrics-server
