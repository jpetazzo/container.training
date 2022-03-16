# Scaling with custom metrics

- The HorizontalPodAutoscaler v1 can only scale on Pod CPU usage

- Sometimes, we need to scale using other metrics:

  - memory

  - requests per second

  - latency

  - active sessions

  - items in a work queue

  - ...

- The HorizontalPodAutoscaler v2 can do it!

---

## Requirements

⚠️ Autoscaling on custom metrics is fairly complex!

- We need some metrics system

  (Prometheus is a popular option, but others are possible too)

- We need our metrics (latency, traffic...) to be fed in the system

  (with Prometheus, this might require a custom exporter)

- We need to expose these metrics to Kubernetes

  (Kubernetes doesn't "speak" the Prometheus API)

- Then we can set up autoscaling!

---

## The plan

- We will deploy the DockerCoins demo app

  (one of its components has a bottleneck; its latency will increase under load)

- We will use Prometheus to collect and store metrics

- We will deploy a tiny HTTP latency monitor (a Prometheus *exporter*)

- We will deploy the "Prometheus adapter"

  (mapping Prometheus metrics to Kubernetes-compatible metrics)

- We will create an HorizontalPodAutoscaler 🎉

---

## Deploying DockerCoins

- That's the easy part!

.lab[

- Create a new namespace and switch to it:
  ```bash
  kubectl create namespace customscaling
  kns customscaling
  ```

- Deploy DockerCoins, and scale up the `worker` Deployment:
  ```bash
  kubectl apply -f ~/container.training/k8s/dockercoins.yaml
  kubectl scale deployment worker --replicas=10
  ```

]

---

## Current state of affairs

- The `rng` service is a bottleneck

  (it cannot handle more than 10 requests/second)

- With enough traffic, its latency increases

  (by about 100ms per `worker` Pod after the 3rd worker)

.lab[

- Check the `webui` port and open it in your browser:
  ```bash
  kubectl get service webui
  ```

- Check the `rng` ClusterIP and test it with e.g. `httping`:
  ```bash
  kubectl get service rng
  ```

]

---

## Measuring latency

- We will use a tiny custom Prometheus exporter, [httplat](https://github.com/jpetazzo/httplat)

- `httplat` exposes Prometheus metrics on port 9080 (by default)

- It monitors exactly one URL, that must be passed as a command-line argument

.lab[

- Deploy `httplat`:
  ```bash
  kubectl create deployment httplat --image=jpetazzo/httplat -- httplat http://rng/
  ```

- Expose it:
  ```bash
  kubectl expose deployment httplat --port=9080
  ```

]

---

class: extra-details

## Measuring latency in the real world

- We are using this tiny custom exporter for simplicity

- A more common method to collect latency is to use a service mesh

- A service mesh can usually collect latency for *all* services automatically

---

## Install Prometheus

- We will use the Prometheus community Helm chart

  (because we can configure it dynamically with annotations)

.lab[

- If it's not installed yet on the cluster, install Prometheus:
  ```bash
    helm upgrade --install prometheus prometheus \
         --repo https://prometheus-community.github.io/helm-charts \
         --namespace prometheus --create-namespace \
         --set server.service.type=NodePort \
         --set server.service.nodePort=30090 \
         --set server.persistentVolume.enabled=false \
         --set alertmanager.enabled=false
  ```

]

---

## Configure Prometheus

- We can use annotations to tell Prometheus to collect the metrics

.lab[

- Tell Prometheus to "scrape" our latency exporter:
  ```bash
    kubectl annotate service httplat \
            prometheus.io/scrape=true \
            prometheus.io/port=9080 \
            prometheus.io/path=/metrics
  ```

]

If you deployed Prometheus differently, you might have to configure it manually.

You'll need to instruct it to scrape http://httplat.customscaling.svc:9080/metrics.

---

## Make sure that metrics get collected

- Before moving on, confirm that Prometheus has our metrics

.lab[

- Connect to Prometheus

  (if you installed it like instructed above, it is exposed as a NodePort on port 30090)

- Check that `httplat` metrics are available

- You can try to graph the following PromQL expression:
  ```
  rate(httplat_latency_seconds_sum[2m])/rate(httplat_latency_seconds_count[2m])
  ```

]

---

## Troubleshooting

- Make sure that the exporter works:

  - get the ClusterIP of the exporter with `kubectl get svc httplat`

  - `curl http://<ClusterIP>:9080/metrics`

  - check that the result includes the `httplat` histogram

- Make sure that Prometheus is scraping the exporter:

  - go to `Status` / `Targets` in Prometheus

  - make sure that `httplat` shows up in there

---

## Creating the autoscaling policy

- We need custom YAML (we can't use the `kubectl autoscale` command)

- It must specify `scaleTargetRef`, the resource to scale

  - any resource with a `scale` sub-resource will do

  - this includes Deployment, ReplicaSet, StatefulSet...

- It must specify one or more `metrics` to look at

  - if multiple metrics are given, the autoscaler will "do the math" for each one

  - it will then keep the largest result

---

## Details about the `metrics` list

- Each item will look like this:
  ```yaml
    - type: <TYPE-OF-METRIC>
      <TYPE-OF-METRIC>:
        metric:
          name: <NAME-OF-METRIC>
          <...optional selector (mandatory for External metrics)...>
        target:
          type: <TYPE-OF-TARGET>
          <TYPE-OF-TARGET>: <VALUE>
        <describedObject field, for Object metrics>
  ```

`<TYPE-OF-METRIC>` can be `Resource`, `Pods`, `Object`, or `External`.

`<TYPE-OF-TARGET>` can be `Utilization`, `Value`, or `AverageValue`.

Let's explain the 4 different `<TYPE-OF-METRIC>` values!

---

## `Resource`

Use "classic" metrics served by `metrics-server` (`cpu` and `memory`).

```yaml
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

Compute average *utilization* (usage/requests) across pods.

It's also possible to specify `Value` or `AverageValue` instead of `Utilization`.

(To scale according to "raw" CPU or memory usage.)

---

## `Pods`

Use custom metrics. These are still "per-Pod" metrics.

```yaml
  - type: Pods
    pods:
      metric:
        name: packets-per-second
      target:
        type: AverageValue
        averageValue: 1k
```

`type:` *must* be `AverageValue`.

(It cannot be `Utilization`, since these can't be used in Pod `requests`.)

---

## `Object`

Use custom metrics. These metrics are "linked" to any arbitrary resource.

(E.g. a Deployment, Service, Ingress, ...)

```yaml
  - type: Object
    object:
      metric:
        name: requests-per-second
      describedObject:
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        name: main-route
      target:
        type: AverageValue
        value: 100
```

`type:` can be `Value` or `AverageValue` (see next slide for details).

---

## `Value` vs `AverageValue`

- `Value`

  - use the value as-is

  - useful to pace a client or producer

  - "target a specific total load on a specific endpoint or queue"

- `AverageValue`

  - divide the value by the number of pods

  - useful to scale a server or consumer

  - "scale our systems to meet a given SLA/SLO"

---

## `External`

Use arbitrary metrics. The series to use is specified with a label selector.

```yaml
  - type: External
    external:
      metric:
        name: queue_messages_ready
        selector: "queue=worker_tasks"
      target:
        type: AverageValue
        averageValue: 30
```

The `selector` will be passed along when querying the metrics API.

Its meaninng is implementation-dependent.

It may or may not correspond to Kubernetes labels.

---

## One more thing ...

- We can give a `behavior` set of options

- Indicates:

  - how much to scale up/down in a single step

  - a *stabilization window* to avoid hysteresis effects

- The default stabilization window is 15 seconds for `scaleUp`

  (we might want to change that!)

---

Putting togeher @@LINK[k8s/hpa-v2-pa-httplat.yaml]:

.small[
```yaml
@@INCLUDE[k8s/hpa-v2-pa-httplat.yaml]
```
]

---

## Creating the autoscaling policy

- We will register the policy

- Of course, it won't quite work yet (we're missing the *Prometheus adapter*)

.lab[

- Create the HorizontalPodAutoscaler:
  ```bash
  kubectl apply -f ~/container.training/k8s/hpa-v2-pa-httplat.yaml
  ```

- Check the logs of the `controller-manager`:
  ```bash
  stern --namespace=kube-system --tail=10 controller-manager
  ```

]

After a little while we should see messages like this:
```
no custom metrics API (custom.metrics.k8s.io) registered
```

---

## `custom.metrics.k8s.io`

- The HorizontalPodAutoscaler will get the metrics *from the Kubernetes API itself*

- In our specific case, it will access a resource like this one:
  .small[
  ```
  /apis/custom.metrics.k8s.io/v1beta1/namespaces/customscaling/services/httplat/httplat_latency_seconds
  ```
  ]

- By default, the Kubernetes API server doesn't implement `custom.metrics.k8s.io`

  (we can have a look at `kubectl get apiservices`)

- We need to:

  - start an API service implementing this API group

  - register it with our API server

---

## The Prometheus adapter

- The Prometheus adapter is an open source project:

  https://github.com/DirectXMan12/k8s-prometheus-adapter

- It's a Kubernetes API service implementing API group `custom.metrics.k8s.io`

- It maps the requests it receives to Prometheus metrics

- Exactly what we need!

---

## Deploying the Prometheus adapter

- There is ~~an app~~ a Helm chart for that

.lab[

- Install the Prometheus adapter:
  ```bash
    helm upgrade --install prometheus-adapter prometheus-adapter \
      --repo https://prometheus-community.github.io/helm-charts \
      --namespace=prometheus-adapter --create-namespace \
      --set prometheus.url=http://prometheus-server.prometheus.svc \
      --set prometheus.port=80
  ```

]

- It comes with some default mappings

- But we will need to add `httplat` to these mappings

---

## Configuring the Prometheus adapter

- The Prometheus adapter can be configured/customized through a ConfigMap

- We are going to edit that ConfigMap, then restart the adapter

- We need to add a rule that will say:

  - all the metrics series named `httplat_latency_seconds_sum` ...

  - ... belong to *Services* ...

  - ... the name of the Service and its Namespace are indicated by the `kubernetes_name` and `kubernetes_namespace` Prometheus tags respectively ...

  - ... and the exact value to use should be the following PromQL expression

---

## The mapping rule

Here is the rule that we need to add to the configuration:

```yaml
    - seriesQuery: 'httplat_latency_seconds_sum{namespace!="",service!=""}'
      resources:
        overrides:
          namespace:
            resource: namespace
          service:
            resource: service
      name:
        matches: "httplat_latency_seconds_sum"
        as: "httplat_latency_seconds"
      metricsQuery: |
        rate(httplat_latency_seconds_sum{<<.LabelMatchers>>}[2m])/rate(httplat_latency_seconds_count{<<.LabelMatchers>>}[2m])
```

(I built it following the [walkthrough](https://github.com/DirectXMan12/k8s-prometheus-adapter/blob/master/docs/config-walkthrough.md
) in the Prometheus adapter documentation.)

---

## Editing the adapter's configuration

.lab[

- Edit the adapter's ConfigMap:
  ```bash
  kubectl edit configmap prometheus-adapter --namespace=prometheus-adapter
  ```

- Add the new rule in the `rules` section, at the end of the configuration file

- Save, quit

- Restart the Prometheus adapter:
  ```bash
  kubectl rollout restart deployment --namespace=prometheus-adapter prometheus-adapter
  ```

]

---

## Witness the marvel of custom autoscaling

(Sort of)

- After a short while, the `rng` Deployment will scale up

- It should scale up until the latency drops below 100ms

  (and continue to scale up a little bit more after that)

- Then, since the latency will be well below 100ms, it will scale down

- ... and back up again, etc.

(See pictures on next slides!)

---

class: pic

![Latency over time](images/hpa-v2-pa-latency.png)

---

class: pic

![Number of pods over time](images/hpa-v2-pa-pods.png)

---

## What's going on?

- The autoscaler's information is slightly out of date

  (not by much; probably between 1 and 2 minute)

- It's enough to cause the oscillations to happen

- One possible fix is to tell the autoscaler to wait a bit after each action

- It will reduce oscillations, but will also slow down its reaction time

  (and therefore, how fast it reacts to a peak of traffic)

---

## What's going on? Take 2

- As soon as the measured latency is *significantly* below our target (100ms) ...

  the autoscaler tries to scale down

- If the latency is measured at 20ms ...

  the autoscaler will try to *divide the number of pods by five!*

- One possible solution: apply a formula to the measured latency,
  so that values between e.g. 10 and 100ms get very close to 100ms.

- Another solution: instead of targetting for a specific latency,
  target a 95th percentile latency or something similar, using
  a more advanced PromQL expression (and leveraging the fact that
  we have histograms instead of raw values).

---

## Troubleshooting

Check that the adapter registered itself correctly:
```bash
kubectl get apiservices | grep metrics
```

Check that the adapter correctly serves metrics:
```bash
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1
```

Check that our `httplat` metrics are available:
```bash
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1\
/namespaces/customscaling/services/httplat/httplat_latency_seconds
```

Also check the logs of the `prometheus-adapter` and the `kube-controller-manager`.

---

## Useful links

- [Horizontal Pod Autoscaler walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/) in the Kubernetes documentation

- [Autoscaling design proposal](https://github.com/kubernetes/community/tree/master/contributors/design-proposals/autoscaling)

- [Kubernetes custom metrics API alternative implementations](https://github.com/kubernetes/metrics/blob/master/IMPLEMENTATIONS.md)

- [Prometheus adapter configuration walkthrough](https://github.com/DirectXMan12/k8s-prometheus-adapter/blob/master/docs/config-walkthrough.md)

---

## Discussion

- This system works great if we have a single, centralized metrics system

  (and the corresponding "adapter" to expose these metrics through the Kubernetes API)

- If we have metrics in multiple places, we must aggregate them

  (good news: Prometheus has exporters for almost everything!)

- It is complex and has a steep learning curve

- Another approach is [KEDA](https://keda.sh/)

???

:EN:- Autoscaling with custom metrics
:FR:- Suivi de charge avancé (HPAv2)
