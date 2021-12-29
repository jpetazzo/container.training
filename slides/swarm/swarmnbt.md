class: nbt, extra-details

## Measuring cluster-wide network conditions

- Since we have built-in, cluster-wide discovery, it's relatively straightforward
  to monitor the whole cluster automatically

- [Alexandros Mavrogiannis](https://github.com/alexmavr) wrote
  [Swarm NBT](https://github.com/alexmavr/swarm-nbt), a tool doing exactly that!

.lab[

- Start Swarm NBT:
  ```bash
    docker run --rm -v inventory:/inventory \
           -v /var/run/docker.sock:/var/run/docker.sock \
           alexmavr/swarm-nbt start
  ```

]

Note: in this mode, Swarm NBT connects to the Docker API socket,
and issues additional API requests to start all the components it needs.

---

class: nbt, extra-details

## Viewing network conditions with Prometheus

- Swarm NBT relies on Prometheus to scrape and store data

- We can directly consume the Prometheus endpoint to view telemetry data

.lab[

- Point your browser to any Swarm node, on port 9090

  (If you're using Play-With-Docker, click on the (9090) badge)

- In the drop-down, select `icmp_rtt_gauge_seconds`

- Click on "Graph"

]

You are now seeing ICMP latency across your cluster.

---

class: nbt, in-person, extra-details

## Viewing network conditions with Grafana

- If you are using a "real" cluster (not Play-With-Docker) you can use Grafana

.lab[

- Start Grafana with `docker service create -p 3000:3000 grafana`
- Point your browser to Grafana, on port 3000 on any Swarm node
- Login with username `admin` and password `admin`
- Click on the top-left menu and browse to Data Sources
- Create a prometheus datasource with any name
- Point it to http://any-node-IP:9090
- Set access to "direct" and leave credentials blank
- Click on the top-left menu, highlight "Dashboards" and select the "Import" option
- Copy-paste [this JSON payload](
  https://raw.githubusercontent.com/alexmavr/swarm-nbt/master/grafana.json),
  then use the Prometheus Data Source defined before
- Poke around the dashboard that magically appeared!

]
