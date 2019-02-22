# Logging

In this chapter, we will explain the different ways to send logs from containers.

We will then show one particular method in action, using ELK and Docker's logging drivers.

---

## There are many ways to send logs

- The simplest method is to write on the standard output and error.

- Applications can write their logs to local files.

  (The files are usually periodically rotated and compressed.)

- It is also very common (on UNIX systems) to use syslog.

  (The logs are collected by syslogd or an equivalent like journald.)

- In large applications with many components, it is common to use a logging service.

  (The code uses a library to send messages to the logging service.)

*All these methods are available with containers.*

---

## Writing on stdout/stderr

- The standard output and error of containers is managed by the container engine.

- This means that each line written by the container is received by the engine.

- The engine can then do "whatever" with these log lines.

- With Docker, the default configuration is to write the logs to local files.

- The files can then be queried with e.g. `docker logs` (and the equivalent API request).

- This can be customized, as we will see later.

---

## Writing to local files

- If we write to files, it is possible to access them but cumbersome.

  (We have to use `docker exec` or `docker cp`.)

- Furthermore, if the container is stopped, we cannot use `docker exec`.

- If the container is deleted, the logs disappear.

- What should we do for programs who can only log to local files?

--

- There are multiple solutions.

---

## Using a volume or bind mount

- Instead of writing logs to a normal directory, we can place them on a volume.

- The volume can be accessed by other containers.

- We can run a program like `filebeat` in another container accessing the same volume.

  (`filebeat` reads local log files continuously, like `tail -f`, and sends them
  to a centralized system like ElasticSearch.)

- We can also use a bind mount, e.g. `-v /var/log/containers/www:/var/log/tomcat`.

- The container will write log files to a directory mapped to a host directory.

- The log files will appear on the host and be consumable directly from the host.

---

## Using logging services

- We can use logging frameworks (like log4j or the Python `logging` package).

- These frameworks require some code and/or configuration in our application code.

- These mechanisms can be used identically inside or outside of containers.

- Sometimes, we can leverage containerized networking to simplify their setup.

- For instance, our code can send log messages to a server named `log`.

- The name `log` will resolve to different addresses in development, production, etc.

---

## Using syslog

- What if our code (or the program we are running in containers) uses syslog?

- One possibility is to run a syslog daemon in the container.

- Then that daemon can be setup to write to local files or forward to the network.

- Under the hood, syslog clients connect to a local UNIX socket, `/dev/log`.

- We can expose a syslog socket to the container (by using a volume or bind-mount).

- Then just create a symlink from `/dev/log` to the syslog socket.

- Voilà!

---

## Using logging drivers

- If we log to stdout and stderr, the container engine receives the log messages.

- The Docker Engine has a modular logging system with many plugins, including:

  - json-file (the default one)
  - syslog
  - journald
  - gelf
  - fluentd
  - splunk
  - etc.

- Each plugin can process and forward the logs to another process or system.

---

## A word of warning about `json-file`

- By default, log file size is unlimited.

- This means that a very verbose container *will* use up all your disk space.

  (Or a less verbose container, but running for a very long time.)

- Log rotation can be enabled by setting a `max-size` option.

- Older log files can be removed by setting a `max-file` option.

- Just like other logging options, these can be set per container, or globally.

Example:
```bash
$ docker run --log-opt max-size=10m --log-opt max-file=3 elasticsearch
```

---

## Demo: sending logs to ELK

- We are going to deploy an ELK stack.

- It will accept logs over a GELF socket.

- We will run a few containers with the `gelf` logging driver.

- We will then see our logs in Kibana, the web interface provided by ELK.

*Important foreword: this is not an "official" or "recommended"
setup; it is just an example. We used ELK in this demo because
it's a popular setup and we keep being asked about it; but you
will have equal success with Fluent or other logging stacks!*

---

## What's in an ELK stack?

- ELK is three components:

  - ElasticSearch (to store and index log entries)

  - Logstash (to receive log entries from various
    sources, process them, and forward them to various
    destinations)

  - Kibana (to view/search log entries with a nice UI)

- The only component that we will configure is Logstash

- We will accept log entries using the GELF protocol

- Log entries will be stored in ElasticSearch,
  <br/>and displayed on Logstash's stdout for debugging

---

## Running ELK

- We are going to use a Compose file describing the ELK stack.

- The Compose file is in the container.training repository on GitHub.

```bash
$ git clone https://github.com/jpetazzo/container.training
$ cd container.training
$ cd elk
$ docker-compose up
```

- Let's have a look at the Compose file while it's deploying.

---

## Our basic ELK deployment

- We are using images from the Docker Hub: `elasticsearch`, `logstash`, `kibana`.

- We don't need to change the configuration of ElasticSearch.

- We need to tell Kibana the address of ElasticSearch:

  - it is set with the `ELASTICSEARCH_URL` environment variable,

  - by default it is `localhost:9200`, we change it to `elasticsearch:9200`.

- We need to configure Logstash:

  - we pass the entire configuration file through command-line arguments,

  - this is a hack so that we don't have to create an image just for the config.

---

## Sending logs to ELK

- The ELK stack accepts log messages through a GELF socket.

- The GELF socket listens on UDP port 12201.

- To send a message, we need to change the logging driver used by Docker.

- This can be done globally (by reconfiguring the Engine) or on a per-container basis.

- Let's override the logging driver for a single container:

```bash
$ docker run --log-driver=gelf --log-opt=gelf-address=udp://localhost:12201 \
  alpine echo hello world
```

---

## Viewing the logs in ELK

- Connect to the Kibana interface.

- It is exposed on port 5601.

- Browse http://X.X.X.X:5601.

---

## "Configuring" Kibana

- Kibana should offer you to "Configure an index pattern":
  <br/>in the "Time-field name" drop down, select "@timestamp", and hit the
  "Create" button.

- Then:

  - click "Discover" (in the top-left corner),
  - click "Last 15 minutes" (in the top-right corner),
  - click "Last 1 hour" (in the list in the middle),
  - click "Auto-refresh" (top-right corner),
  - click "5 seconds" (top-left of the list).

- You should see a series of green bars (with one new green bar every minute).

- Our 'hello world' message should be visible there.

---

## Important afterword

**This is not a "production-grade" setup.**

It is just an educational example. Since we have only
one node , we did set up a single
ElasticSearch instance and a single Logstash instance.

In a production setup, you need an ElasticSearch cluster
(both for capacity and availability reasons). You also
need multiple Logstash instances.

And if you want to withstand
bursts of logs, you need some kind of message queue:
Redis if you're cheap, Kafka if you want to make sure
that you don't drop messages on the floor. Good luck.

If you want to learn more about the GELF driver,
have a look at [this blog post](
https://jpetazzo.github.io/2017/01/20/docker-logging-gelf/).
