# Checking pod and node resource usage

- Since Kubernetes 1.8, metrics are collected by the [resource metrics pipeline](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)

- The resource metrics pipeline is:

  - optional (Kubernetes can function without it)

  - necessary for some features (like the Horizontal Pod Autoscaler)

  - exposed through the Kubernetes API using the [aggregation layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)

  - usually implemented by the "metrics server"

---

## How to know if the metrics server is running?

- The easiest way to know is to run `kubectl top`

.exercise[

- Check if the core metrics pipeline is available:
  ```bash
  kubectl top nodes
  ```

]

If it shows our nodes and their CPU and memory load, we're good!

---

## Installing metrics server

- The metrics server doesn't have any particular requirements

  (it doesn't need persistence, as it doesn't *store* metrics)

- It has its own repository, [kubernetes-incubator/metrics-server](https://github.com/kubernetes-incubator/metrics-server)

- The repository comes with [YAML files for deployment](https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/1.8%2B)

- These files may not work on some clusters

  (e.g. if your node names are not in DNS)

- The container.training repository has a [metrics-server.yaml](https://github.com/jpetazzo/container.training/blob/master/k8s/metrics-server.yaml#L90) file to help with that

  (we can `kubectl apply -f` that file if needed)

---

## Showing container resource usage

- Once the metrics server is running, we can check container resource usage

.exercise[

- Show resource usage across all containers:
  ```bash
  kubectl top pods --containers --all-namespaces
  ```
]

- We can also use selectors (`-l app=...`)

---

## Other tools

- kube-capacity is a great CLI tool to view resources

  (https://github.com/robscott/kube-capacity)

- It can show resource and limits, and compare them with usage

- It can show utilization per node, or per pod

- kube-resource-report can generate HTML reports

  (https://github.com/hjacobs/kube-resource-report)

???

:EN:- The *core metrics pipeline*
:FR:- Le *core metrics pipeline*
