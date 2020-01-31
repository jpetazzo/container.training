# Prometheus

Prometheus is monitoring system with small storage io footprint.

It's quite ubiquitous in the Kubernetes world.

This section is not a description

<!--
FIXME maybe just use prometheus.md and add this file after it?
This way there is not need to write a Prom intro.
-->

---

## Prometheus exporter

We want to provide a Prometheus exporter.

A Prometheus exporter is an HTTP endpoint serving a response like this one:

```
 # HELP http_requests_total The total number of HTTP requests.
 # TYPE http_requests_total counter
 http_requests_total{method="post",code="200"} 1027 1395066363000
 http_requests_total{method="post",code="400"}    3 1395066363000

 # Minimalistic line:
 metric_without_timestamp_and_labels 12.47
```

---

## Implementing a Prometheus exporter

Multiple strategies can be used:

- Implement the exporter in the application itself

  (especially if it's already an  HTTP server)

- Use building blocks that may already expose such an endpoint

  (puma, uwsgi)

- Add a sidecar exporter that leverages and adapts an existing monitoring channel

  (e.g. JMX for Java applications)

---

## Implementing a Prometheus exporter

- The Prometheus client libraries are often the easiest solution

- They offer multiple ways of integration, including:

  - "I'm already running a web server, just add a monitoring route"

  - "I don't have a web server (or I want another one), please run one in a thread"

- Client libraries for various languages:

  - https://github.com/prometheus/client_python

  - https://github.com/prometheus/client_ruby

  - https://github.com/prometheus/client_golang

  (Can you see the pattern?)

---

## Adding a sidecar exporter

- There are many exporters available already:

  https://prometheus.io/docs/instrumenting/exporters/

- These are "translators" from one monitoring channel to another

- Writing your own is not complicated

  (using the client libraries mentioned previously)

- Avoid exposing the internal monitoring channel more than enough

  (the app and its sidecars run in the same network namespace,
  <br/>so they can communicate over `localhost`)

---

## Configuring the Prometheus server

- We need to tell the Prometheus server to *scrape* our exporter

- Prometheus has a very flexible "service discovery" mechanism

  (to discover and enumerate the targets that it should scrape)

- Depending on how we installed Prometheus, various methods might be available

---

## Configuring Prometheus, option 1

- Edit `prometheus.conf`

- Always possible

  (we should always have a Prometheus configuration file somewhere!)

- Dangerous and error-prone

  (if we get it wrong, it is very easy to break Prometheus)

- Hard to maintain

  (the file will grow over time, and might accumulate obsolete information)

---

## Configuring Prometheus, option 2

- Add *annotations* to the pods or services to monitor

- We can do that if Prometheus is installed with the official Helm chart

- Prometheus will detect these annotations and automatically start scraping

- Example:
  ```yaml
    annotations:
      prometheus.io/port: 9090
      prometheus.io/path: /metrics
  ```

---

## Configuring Prometheus, option 3

- Create a ServiceMonitor custom resource

- We can do that if we are using the CoreOS Prometheus operator

- See the [Prometheus operator documentation](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitor) for more details
