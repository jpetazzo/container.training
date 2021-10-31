# Exercise — Helm Charts

- We want to deploy dockercoins with a Helm chart

- We want to have a "generic chart" and instantiate it 5 times

  (once for each service)

- We will pass values to the chart to customize it for each component

  (to indicate which image to use, which ports to expose, etc.)

- We'll use `helm create` as a starting point for our generic chart

---

## Goal

- Have a directory with the generic chart

  (e.g. `generic-chart`)

- Have 5 value files

  (e.g. `hasher.yml`, `redis.yml`, `rng.yml`, `webui.yml`, `worker.yml`)

- Be able to install dockercoins by running 5 times:

  `helm install X ./generic-chart --values=X.yml`

---

## Hints

- There are many little things to tweak in the generic chart

  (service names, port numbers, healthchecks...)

- Check the training slides if you need a refresher!

---

## Bonus 1

- Minimize the amount of values that have to be set

- Option 1: no values at all for `rng` and `hasher`

  (default values assume HTTP service listening on port 80)

- Option 2: no values at all for `worker`

  (default values assume worker container with no service)


---

## Bonus 2

- Handle healthchecks

- Make sure that healthchecks are enabled in HTTP services

- ...But not in Redis or in the worker

---

## Bonus 3

- Make it easy to change image versions

- E.g. change `v0.1` to `v0.2` by changing only *one* thing in *one* place

---

## Bonus 4

- Make it easy to use images on a different registry

- We can assume that the images will always have the same names

  (`hasher`, `rng`, `webui`, `worker`)

- And the same tag

  (`v0.1`)
