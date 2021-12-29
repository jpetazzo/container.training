class: self-paced

## Before we continue ...

The following section assumes that you have a 5-nodes Swarm cluster.

If you come here from a previous tutorial and still have your cluster: great!

Otherwise: check [part 1](#part-1) to learn how to set up your own cluster.

We pick up exactly where we left you, so we assume that you have:

- a Swarm cluster with at least 3 nodes,

- a self-hosted registry,

- DockerCoins up and running.

The next slide has a cheat sheet if you need to set that up in a pinch.

---

class: self-paced

## Catching up

Assuming you have 5 nodes provided by
[Play-With-Docker](https://www.play-with-docker/), do this from `node1`:

```bash
docker swarm init --advertise-addr eth0
TOKEN=$(docker swarm join-token -q manager)
for N in $(seq 2 5); do
  DOCKER_HOST=tcp://node$N:2375 docker swarm join --token $TOKEN node1:2377
done
git clone https://@@GITREPO@@
cd container.training/stacks
docker stack deploy --compose-file registry.yml registry
docker-compose -f dockercoins.yml build
docker-compose -f dockercoins.yml push
docker stack deploy --compose-file dockercoins.yml dockercoins
```

You should now be able to connect to port 8000 and see the DockerCoins web UI.
