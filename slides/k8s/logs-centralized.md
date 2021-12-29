# Centralized logging

- Using `kubectl` or `stern` is simple; but it has drawbacks:

  - when a node goes down, its logs are not available anymore

  - we can only dump or stream logs; we want to search/index/count...

- We want to send all our logs to a single place

- We want to parse them (e.g. for HTTP logs) and index them

- We want a nice web dashboard

--

- We are going to deploy an EFK stack

---

## What is EFK?

- EFK is three components:

  - ElasticSearch (to store and index log entries)

  - Fluentd (to get container logs, process them, and put them in ElasticSearch)

  - Kibana (to view/search log entries with a nice UI)

- The only component that we need to access from outside the cluster will be Kibana

---

## Deploying EFK on our cluster

- We are going to use a YAML file describing all the required resources

.lab[

- Load the YAML file into our cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/efk.yaml
  ```

]

If we [look at the YAML file](https://github.com/jpetazzo/container.training/blob/master/k8s/efk.yaml), we see that
it creates a daemon set, two deployments, two services,
and a few roles and role bindings (to give fluentd the required permissions).

---

## The itinerary of a log line (before Fluentd)

- A container writes a line on stdout or stderr

- Both are typically piped to the container engine (Docker or otherwise)

- The container engine reads the line, and sends it to a logging driver

- The timestamp and stream (stdout or stderr) is added to the log line

- With the default configuration for Kubernetes, the line is written to a JSON file

  (`/var/log/containers/pod-name_namespace_container-id.log`)

- That file is read when we invoke `kubectl logs`; we can access it directly too

---

## The itinerary of a log line (with Fluentd)

- Fluentd runs on each node (thanks to a daemon set)

- It bind-mounts `/var/log/containers` from the host (to access these files)

- It continuously scans this directory for new files; reads them; parses them

- Each log line becomes a JSON object, fully annotated with extra information:
  <br/>container id, pod name, Kubernetes labels...

- These JSON objects are stored in ElasticSearch

- ElasticSearch indexes the JSON objects

- We can access the logs through Kibana (and perform searches, counts, etc.)

---

## Accessing Kibana

- Kibana offers a web interface that is relatively straightforward

- Let's check it out!

.lab[

- Check which `NodePort` was allocated to Kibana:
  ```bash
  kubectl get svc kibana
  ```

- With our web browser, connect to Kibana

]

---

## Using Kibana

*Note: this is not a Kibana workshop! So this section is deliberately very terse.*

- The first time you connect to Kibana, you must "configure an index pattern"

- Just use the one that is suggested, `@timestamp`.red[*]

- Then click "Discover" (in the top-left corner)

- You should see container logs

- Advice: in the left column, select a few fields to display, e.g.:

  `kubernetes.host`, `kubernetes.pod_name`, `stream`, `log`

.red[*]If you don't see `@timestamp`, it's probably because no logs exist yet.
<br/>Wait a bit, and double-check the logging pipeline!

---

## Caveat emptor

We are using EFK because it is relatively straightforward
to deploy on Kubernetes, without having to redeploy or reconfigure
our cluster. But it doesn't mean that it will always be the best
option for your use-case. If you are running Kubernetes in the
cloud, you might consider using the cloud provider's logging
infrastructure (if it can be integrated with Kubernetes).

The deployment method that we will use here has been simplified:
there is only one ElasticSearch node. In a real deployment, you
might use a cluster, both for performance and reliability reasons.
But this is outside of the scope of this chapter.

The YAML file that we used creates all the resources in the
`default` namespace, for simplicity. In a real scenario, you will
create the resources in the `kube-system` namespace or in a dedicated namespace.

???

:EN:- Centralizing logs
:FR:- Centraliser les logs
