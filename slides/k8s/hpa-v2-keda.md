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

- We will then use KEDA with a "Prometheus Scaler"

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

## Installing KEDA

- Multiple possibilities, as explained in the [documentation](https://keda.sh/docs/2.12/deploy/)

- For simplicity we can use the YAML version with admission webhooks

---

## Creating a "Scaler"

- With KEDA, instead of creating an HPA policy directly, we create a "Scaled Object"

- The "Scaled Object" will take care of:

  - registering and exposing our custom metric in KEDA'a aggregation layer

  - creating the HPA policy that consumes that metric

- See the [Prometheus Scaler documentation](https://keda.sh/docs/2.12/scalers/prometheus/)

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

???

:EN:- Autoscaling with custom metrics
:FR:- Suivi de charge avancé (HPAv2)
