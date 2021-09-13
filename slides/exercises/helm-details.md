# Exercise - Helm Charts

- We want to deploy dockercoins with a Helm chart

- We want to have a "generic chart" and instantiate it 5 times

  (once for each service)

- We will pass values to the chart to customize it for each component

  (to indicate which image to use, which ports to expose, etc.)

- We'll use `helm create` as a starting point for our generic chart

---


  (using `helm create` to get a generic chart and tweaking that chart)

- Deploy dockercoins by instanciating that chart multiple times

  (one time per service, so 5 times total)

- Create a "meta" Helm chart to install the 5 components of dockercoins

  (using chart dependencies and aliases)

- Bonus: use Bitnami's redis chart for the dockercoins redis component

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

- Create a "meta chart" or "umbrella chart" to install all 5 components

  (so that dockercoins can be installed with a single `helm install` command)

- This will require expressing dependencies, and using the `alias` keyword

---

## Bonus 2

- Replace the `redis` component with an external chart

  (e.g. Bitnami's redis chart)

- This will require to pass extra values to that chart

  (to disable persistence, replication, password authentication)

- This will also require to either:

  - import the chart and tweak it to change the service name

  - add an ExternalName service pointing to the new redis component
