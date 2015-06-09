# Orchestration at scales

Preparation:

- Create VMs with docker-fundamentals script.

- Put `ips.txt` file in `prepare-vms` directory.
- Generate HTML file.
- Open it in Chrome.
- Transform to PDF.
- Print it.

- Make sure that you have SSH keys loaded (`ssh-add -l`).
- Source `rc`.
- Run `pcopykey`.
- Source `postprep.rc`.
  (This will install a few extra packages, add entries to
  /etc/hosts, generate SSH keys, and deploy them on all hosts.)

- Set one group of machines for instructor's use.
- Remove it from `ips.txt`.
- Log into the first machine.
- Git clone this repo.
- Put up the web server.
- Use cli53 to add an A record for `view.dckr.info`.


# Description


Chaos Monkey.

App: pseudo-cryptocurrency?


- datastore: redis
- rng: microservice generating randomness
- hasher: microservice computing hashes
  (really just computing sha256sum)
- worker: microservice using the previous two
  to "mine" currency; a coin is a random string whose
  hash starts with at least one zero; they are stored
  in the datastore
- webui: display statistics

(Details: use map sha256->randorigin; also maintain
a list of length 1000 containing timestamps;
compute hash speed by CARD/(NOW()-oldest_ts))

Initial worker has a bug, and takes only 4 first
bytes of seed

## Intro to the environment

- SSH with password
- SSH with keys
- docker run blahblah
- sudo
- parallel-ssh example

## Intro to the app

## Deploy app on single machine

- Docker Compose
- frontend, backend, worker, datastore
- check CPU usage with docker top; docker stats; top
- cadvisor
- introduce ambassador/balancer
- scale appropriately
- fix bug, redeploy

## Clean up

- Stop all containers

## Get started with Swarm

- Explain that machine would take care of this
- Enable SSL certs everywhere
- Create token
- Start swarm master on node1
- Start swarm agent everywhere
- Point CLI to swarm master
- Check docker info, docker version
- Run a few hello worlds

## Deploy with Swarm

- compose up -> doesn't work because build
- docker-compose-tag + push
- docker-compose-pull 
- replace each "linked-to" service by ambassador + single service
  - workers: as is
  - redis: single service + amba
  - backend: scaled + lb; lb is haproxy with net:container
- scale up and see results
- check cadvisor

## Deploy with Mesos




# TODO

+ write pseudo miner
- write deployment scripts
- write chaos monkey
- docker-compose-tag
- docker-compose-pull
- haproxy ambassador
- docker-compose 1.3



