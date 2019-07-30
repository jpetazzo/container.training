# Elasticsearch + Fluentd + Kibana

This is a variation on the classic "ELK" stack.

The [fluentd](fluentd/) subdirectory contains a Dockerfile to build
a fluentd image embarking a simple configuration file, accepting log
entries on port 24224 and storing them in Elasticsearch in a format
that Kibana can use.

You can also use a pre-built image, `jpetazzo/fluentd:v0.1`
(e.g. if you want to deploy on a cluster and don't want to deploy
your own registry).

Once this fluentd container is running, and assuming you expose
its port 24224/tcp somehow, you can send container logs to fluentd
by using Docker's fluentd logging driver.

You can bring up the whole stack with the associated Compoes file.
With Swarm mode, you can bring up the whole stack like this:

```bash
docker network create efk --driver overlay
docker service create --network efk \
       --name elasticsearch elasticsearch:2
docker service create --network efk --publish 5601:5601 \
       --name kibana kibana
docker service create --network efk --publish 24224:24224 \
       --name fluentd jpetazzo/fluentd:v0.1
```

And then, from any node on your cluster, you can send logs to fluentd like this:

```bash
docker run --log-driver fluentd --log-opt fluentd-address=localhost:24224 \
  alpine echo ohai there
```
