name: logging

# Centralized logging

- We want to send all our container logs to a central place

- If that place could offer a nice web dashboard too, that'd be nice

--

- We are going to deploy an ELK stack

- It will accept logs over a GELF socket

- We will update our services to send logs through the GELF logging driver

---

# Setting up ELK to store container logs

*Important foreword: this is not an "official" or "recommended"
setup; it is just an example. We used ELK in this demo because
it's a popular setup and we keep being asked about it; but you
will have equal success with Fluent or other logging stacks!*

What we will do:

- Spin up an ELK stack with services

- Gaze at the spiffy Kibana web UI

- Manually send a few log entries using one-shot containers

- Set our containers up to send their logs to Logstash

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

class: elk-manual

## Setting up ELK

- We need three containers: ElasticSearch, Logstash, Kibana

- We will place them on a common network, `logging`

.exercise[

- Create the network:
  ```bash
  docker network create --driver overlay logging
  ```

- Create the ElasticSearch service:
  ```bash
  docker service create --network logging --name elasticsearch elasticsearch:2.4
  ```

]

---

class: elk-manual

## Setting up Kibana

- Kibana exposes the web UI

- Its default port (5601) needs to be published

- It needs a tiny bit of configuration: the address of the ElasticSearch service

- We don't want Kibana logs to show up in Kibana (it would create clutter)
  <br/>so we tell Logspout to ignore them

.exercise[

- Create the Kibana service:
  ```bash
  docker service create --network logging --name kibana --publish 5601:5601 \
         -e ELASTICSEARCH_URL=http://elasticsearch:9200 kibana:4.6
  ```

]

---

class: elk-manual

## Setting up Logstash

- Logstash needs some configuration to listen to GELF messages and send them to ElasticSearch

- We could author a custom image bundling this configuration

- We can also pass the [configuration](https://@@GITREPO@@/blob/master/elk/logstash.conf) on the command line

.exercise[

- Create the Logstash service:
  ```bash
    docker service create --network logging --name logstash -p 12201:12201/udp \
           logstash:2.4 -e "$(cat ~/container.training/elk/logstash.conf)"
  ```

]

---

class: elk-manual

## Checking Logstash

- Before proceeding, let's make sure that Logstash started properly

.exercise[

- Lookup the node running the Logstash container:
  ```bash
  docker service ps logstash
  ```

- Connect to that node

]

---

class: elk-manual

## View Logstash logs

.exercise[

- View the logs of the logstash service:
  ```bash
  docker service logs logstash --follow
  ```

  <!-- ```wait "message" => "ok"``` -->
  <!-- ```key ^C``` -->

]

You should see the heartbeat messages:
.small[
```json
{      "message" => "ok",
          "host" => "1a4cfb063d13",
      "@version" => "1",
    "@timestamp" => "2016-06-19T00:45:45.273Z"
}
```
]

---

class: elk-auto

## Deploying our ELK cluster

- We will use a stack file

.exercise[

- Build, ship, and run our ELK stack:
  ```bash
  docker-compose -f elk.yml build
  docker-compose -f elk.yml push
  docker stack deploy -c elk.yml elk
  ```

]

Note: the *build* and *push* steps are not strictly necessary, but they don't hurt!

Let's have a look at the [Compose file](
https://@@GITREPO@@/blob/master/stacks/elk.yml).

---

class: elk-auto

## Checking that our ELK stack works correctly

- Let's view the logs of logstash

  (Who logs the loggers?)

.exercise[

- Stream logstash's logs:
  ```bash
  docker service logs --follow --tail 1 elk_logstash
  ```

]

You should see the heartbeat messages:

.small[
```json
{      "message" => "ok",
          "host" => "1a4cfb063d13",
      "@version" => "1",
    "@timestamp" => "2016-06-19T00:45:45.273Z"
}
```
]

---

## Testing the GELF receiver

- In a new window, we will generate a logging message

- We will use a one-off container, and Docker's GELF logging driver

.exercise[

- Send a test message:
  ```bash
    docker run --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201 \
           --rm alpine echo hello
  ```
]

The test message should show up in the logstash container logs.

---

## Sending logs from a service

- We were sending from a "classic" container so far; let's send logs from a service instead

- We're lucky: the parameters (`--log-driver` and `--log-opt`) are exactly the same!


.exercise[

- Send a test message:
  ```bash
    docker service create \
           --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201 \
           alpine echo hello
  ```

  <!-- ```wait Detected task failure``` -->
  <!-- ```key ^C``` -->

]

The test message should show up as well in the logstash container logs.

--

In fact, *multiple messages will show up, and continue to show up every few seconds!*

---

## Restart conditions

- By default, if a container exits (or is killed with `docker kill`, or runs out of memory ...),
  the Swarm will restart it (possibly on a different machine)

- This behavior can be changed by setting the *restart condition* parameter

.exercise[

- Change the restart condition so that Swarm doesn't try to restart our container forever:
  ```bash
  docker service update `xxx` --restart-condition none
  ```
]

Available restart conditions are `none`, `any`, and `on-error`.

You can also set `--restart-delay`, `--restart-max-attempts`, and `--restart-window`.

---

## Connect to Kibana

- The Kibana web UI is exposed on cluster port 5601

.exercise[

- Connect to port 5601 of your cluster

  - if you're using Play-With-Docker, click on the (5601) badge above the terminal

  - otherwise, open http://(any-node-address):5601/ with your browser

]

---

## "Configuring" Kibana

- If you see a status page with a yellow item, wait a minute and reload
  (Kibana is probably still initializing)

- Kibana should offer you to "Configure an index pattern":
  <br/>in the "Time-field name" drop down, select "@timestamp", and hit the
  "Create" button

- Then:

  - click "Discover" (in the top-left corner)
  - click "Last 15 minutes" (in the top-right corner)
  - click "Last 1 hour" (in the list in the middle)
  - click "Auto-refresh" (top-right corner)
  - click "5 seconds" (top-left of the list)

- You should see a series of green bars (with one new green bar every minute)

---

## Updating our services to use GELF

- We will now inform our Swarm to add GELF logging to all our services

- This is done with the `docker service update` command

- The logging flags are the same as before

.exercise[

- Enable GELF logging for the `rng` service:
  ```bash
    docker service update dockercoins_rng \
           --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201
  ```

]

After ~15 seconds, you should see the log messages in Kibana.

---

## Viewing container logs

- Go back to Kibana

- Container logs should be showing up!

- We can customize the web UI to be more readable

.exercise[

- In the left column, move the mouse over the following
  columns, and click the "Add" button that appears:

  - host
  - container_name
  - message

<!--
  - logsource
  - program
  - message
-->

]

---

## .warning[Don't update stateful services!]

- What would have happened if we had updated the Redis service?

- When a service changes, SwarmKit replaces existing container with new ones

- This is fine for stateless services

- But if you update a stateful service, its data will be lost in the process

- If we updated our Redis service, all our DockerCoins would be lost

---

## Important afterword

**This is not a "production-grade" setup.**

It is just an educational example. We did set up a single
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
