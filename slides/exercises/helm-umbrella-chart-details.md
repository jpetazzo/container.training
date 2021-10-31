# Exercise — Umbrella Charts

- We want to deploy dockercoins with a single Helm chart

- That chart will reuse the "generic chart" created previously

- This will require expressing dependencies, and using the `alias` keyword

- It will also require minor changes in the templates

---

## Goal

- We want to be able to install a copy of dockercoins with:
  ```bash
  helm install dockercoins ./umbrella-chart
  ```

- It should leverage the generic chart created earlier

  (and instanciate it five times, one time per component of dockercoins)

- The values YAML files created earlier should be merged in a single one

---

## Bonus

- We want to replace our redis component with a better one

- We're going to use Bitnami's redis chart

  (find it on the Artifact Hub)

- However, a lot of adjustments will be required!

  (check following slides if you need hints)

---

## Hints (1/2)

- We will probably have to disable persistence

  - by default, the chart enables persistence

  - this works only if we have a default StorageClass

  - this can be disabled by setting a value

- We will also have to disable authentication

  - by default, the chart generates a password for Redis

  - the dockercoins code doesn't use one

  - this can also be changed by setting a value

---

## Hints (2/2)

- The dockercoins code connects to `redis`

- The chart generates different service names

- Option 1:

  - vendor the chart in our umbrella chart
  - change the service name in the chart

- Option 2:

  - add a Service of type ExternalName
  - it will be a DNS alias from `redis` to `redis-whatever.NAMESPACE.svc.cluster.local`
  - for extra points, make the domain configurable
