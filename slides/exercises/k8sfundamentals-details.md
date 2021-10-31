# Exercise — Deploy Dockercoins

- We want to deploy the dockercoins app

- There are 5 components in the app:

  hasher, redis, rng, webui, worker

- We'll use one Deployment for each component

  (see next slide for the images to use)

- We'll connect them with Services

- We'll check that we can access the web UI in a browser

---

## Images

- hasher → `dockercoins/hasher:v0.1`

- redis → `redis`

- rng → `dockercoins/rng:v0.1`

- webui → `dockercoins/webui:v0.1`

- worker → `dockercoins/worker:v0.1`

---

## Goal

- We should be able to see the web UI in our browser

  (with the graph showing approximatiely 3-4 hashes/second)

---

## Hints

- Make sure to expose services with the right ports

  (check the logs of the worker; they indicate the port numbers)

- The web UI can be exposed with a NodePort Service
