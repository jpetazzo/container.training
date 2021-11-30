# Exercise — Deploy Dockercoins

- We want to deploy the dockercoins app

- There are 5 components in the app:

  hasher, redis, rng, webui, worker

- We'll use one Deployment for each component

  (created with `kubectl create deployment`)

- We'll connect them with Services

  (create with `kubectl expose`)

---

## Images

- We'll use the following images:

  - hasher → `dockercoins/hasher:v0.1`

  - redis → `redis`

  - rng → `dockercoins/rng:v0.1`

  - webui → `dockercoins/webui:v0.1`

  - worker → `dockercoins/worker:v0.1`

- All services should be internal services, except the web UI

  (since we want to be able to connect to the web UI from outside)

---

class: pic

![Dockercoins architecture diagram](images/dockercoins-diagram.png)

---

## Goal

- We should be able to see the web UI in our browser

  (with the graph showing approximately 3-4 hashes/second)

---

## Hints

- Make sure to expose services with the right ports

  (check the logs of the worker; they indicate the port numbers)

- The web UI can be exposed with a NodePort or LoadBalancer Service
