# Prometheus

Prometheus is a monitoring system with small storage I/O footprint

It's quite ubiquitous in the kubernetes world.

This section is not a description of prometheus.

*Note: More on prometheus next day*

---
## Prometheus endpoint

- Prometheus "pull" metrics from different HTTP endpoint

- The goal for the developper is to expose an HTTP endoint for prometheus. Sample response:

.small[
```
 # HELP http_requests_total The total number of HTTP requests.
 # TYPE http_requests_total counter
 http_requests_total{method="post",code="200"} 1027 1395066363000
 http_requests_total{method="post",code="400"}    3 1395066363000

 # Minimalistic line:
 metric_without_timestamp_and_labels 12.47
```
]

To achieve this multiple strategies could be used:

- developping in the application itself (especialy if it's already an httpserver)

- using building blocks that may already expose such endpoint (puma, uwsgi)

- Add sidecar exporter that leverage an already existing monitoring channel (ex: JMX)

---
## Developing prometheus endpoint

- Using prometheus client libraries is often the easier

- Offer multiple ways of integrations:

    - from: I run already a web server, just add a monitoring route

    - to: please run a full web server in a thread.

Links (do you see a pattern ?):
  - https://github.com/prometheus/client_python
  - https://github.com/prometheus/client_ruby
  - https://github.com/prometheus/client_golang

---
## Add sidecar Exporter

- There is plenty of already existing "exporter":

  - https://prometheus.io/docs/instrumenting/exporters/

- Those are "translators" from one monitoring channel to another

- Writing your own is not complicated (using previous client libraries)

- Try to not expose monitoring channel more than needed. Often localhost is enough
    (sidecars run in the same network namespace as other containers)

---
## Ok! and then change prometheus conf ?

- Well, not really. It achievable this way, but...

- Prometheus has good service discovery paired with kubernetes.

- Depending on how we installed prometheus, we just need:

    - pods annotations:

       ```
        annotations:
          prometheus.io/port: 9090
          prometheus.io/path: /metrics
       ```

    - *service monitor* custom resource object
.small[
        https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitor
]

*Note: More on prometheus next day*
