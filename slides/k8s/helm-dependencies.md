# Charts using other charts

- Helm charts can have *dependencies* on other charts

- These dependencies will help us to share or reuse components

  (so that we write and maintain less manifests, less templates, less code!)

- As an example, we will use a community chart for Redis

- This will help people who write charts, and people who use them

- ... And potentially remove a lot of code! ✌️

---

## Redis in DockerCoins

- In the DockerCoins demo app, we have 5 components:

  - 2 internal webservices
  - 1 worker
  - 1 public web UI
  - 1 Redis data store

- Every component is running some custom code, except Redis

- Every component is using a custom image, except Redis

  (which is using the official `redis` image)

- Could we use a standard chart for Redis?

- Yes! Dependencies to the rescue!

---

## Adding our dependency

- First, we will add the dependency to the `Chart.yaml` file

- Then, we will ask Helm to download that dependency

- We will also *lock* the dependency

  (lock it to a specific version, to ensure reproducibility)

---

## Declaring the dependency

- First, let's edit `Chart.yaml`

.lab[

- In `Chart.yaml`, fill the `dependencies` section:
  ```yaml
    dependencies:
      - name: redis
        version: 0.37.13
        repository: oci://docker.io/cloudpirates
        condition: redis.enabled
  ```

]

Where do that `repository` and `version` come from?

We're assuming here that we did our research,
or that our resident Helm expert advised us to
use that particular Redis chart.

---

## Conditions

- The `condition` field gives us a way to enable/disable the dependency:
  ```yaml
  conditions: redis.enabled
  ```

- Here, we can disable Redis with the Helm flag `--set redis.enabled=false`

  (or set that value in a `values.yaml` file)

- Of course, this is mostly useful for *optional* dependencies

  (otherwise, the app ends up being broken since it'll miss a component)

---

## Lock & Load!

- After adding the dependency, we ask Helm to pin an download it

.lab[

- Ask Helm:
  ```bash
  helm dependency update
  ```

  (Or `helm dep up`)

]

- This wil create `Chart.lock` and fetch the dependency

---

## What's `Chart.lock`?

- This is a common pattern with dependencies

  (see also: `Gemfile.lock`, `package.json.lock`, and many others)

- This lets us define loose dependencies in `Chart.yaml`

  (e.g. "version 0.37.whatever, but below 0.38")

- But have the exact version used in `Chart.lock`

- This ensures reproducible deployments

- `Chart.lock` can (should!) be added to our source tree

- `Chart.lock` can (should!) regularly be updated

---

## Loose dependencies

- Here is an example of loose version requirement:
  ```yaml
    dependencies:
      - name: redis
        version: ">=0.37, <0.38"
        repository: oci://docker.io/cloudpirates
  ```

- This makes sure that we have the most recent version in the 0.37.x train

- ... But without upgrading to version 0.38.x

  (because it might be incompatible)

---

## `build` vs `update`

- Helm actually offers two commands to manage dependencies:

  `helm dependency build` = fetch dependencies listed in `Chart.lock`

  `helm dependency update` = update `Chart.lock` (and run `build`)

- When the dependency gets updated, we can/should:

  - `helm dep up` (update `Chart.lock` and fetch new chart)

  - test!

  - if everything is fine, `git add Chart.lock` and commit

---

## Where are my dependencies?

- Dependencies are downloaded to the `charts/` subdirectory

- When they're downloaded, they stay in compressed format (`.tgz`)

- Should we commit them to our code repository?

- Pros:

  - more resilient to internet/mirror failures/decomissioning

- Cons:

  - can add a lot of weight to the repo if charts are big or change often

  - this can be solved by extra tools like git-lfs

---

## Passing values to dependencies

- DockerCoins expects the `redis` Service to be named `redis`

- Our Redis chart uses a different Service name by default

- We can override it by setting value `fullnameOverride`

- A parent chart can set values for its dependencies

- For example, in the parent's `values.yaml`:

  ```yaml
    redis:                    # Name of the dependency
      fullnameOverride: redis # Value passed to redis
      cluster:                # Other values passed to redis
        enabled: false
  ```

- User can also set variables with `--set=` or with `--values=`

---

## Modifying a subchart

- Ideally, we don't want to edit our subcharts

  (because we would have to redo our modifications each time there is an update)

- But what if we *have to* edit a subchart?

- Example: using [Bitnami's Redis chart][artifacthub-bitnami-redis]

  (in that chart, the Redis service name has a forced `-master` suffix)

[artifacthub-bitnami-redis]: https://artifacthub.io/packages/helm/bitnami/redis

---

class: extra-details

## Why we can't just override the name

- Pull the chart:

  `helm pull oci://docker.io/bitnamicharts/redis --untar`

- Check `redis/templates/master/service.yaml`

- Service name is `{{ template "redis.fullname" . }}-master`

- How do we change this?

---

## Setting dependency variables

- If we set `fullnameOverride` to `redis`:

  - the `{{ template ... }}` block will output `redis`

  - the Service name will be `redis-master`

- Our client expects to connect to a Service named `redis`

- So, what should we do?

---

## Getting rid of the `-master`

- Even if we set that `fullnameOverride`, the Service name will be `redis-master`

- To remove the `-master` suffix, we need to edit the chart itself

- To edit the Redis chart, we need to *embed* it in our own chart

- We need to:

  - decompress the chart

  - adjust `Chart.yaml` accordingly

---

## Embedding a dependency

.lab[

- Get the chart:
  ```yaml
  cd charts
  helm pull oci://docker.io/bitnamicharts/redis --untar
  cd ..
  ```

- Edit `Chart.yaml` and update the `dependencies` section:
  ```yaml
    dependencies:
      - name: redis
        version: '*' # No need to constraint version, from local files
  ```

- Run `helm dep update`

]

---

## Updating the dependency

- Now we can edit the Service name

  (it should be in `charts/redis/templates/redis-master-svc.yaml`)

- Then try to deploy the whole chart!

---

class: extra-details

## Using an `ExternalName` Service

- We could also create a Service of type `ExternalName`

- That Service would resolve to e.g. `redis-master.<NAMESPACE>.svc.cluster.local`

- We need to know the cluster's domain name (`cluster.local` by default)

- This only works in this specific situation

  (Service with a "wrong" name)

- This technique can also be used to point to a service in a different Namespace

---

## Embedding a dependency multiple times

- What if we need multiple copies of the same subchart?

  (for instance, if we need two completely different Redis servers)

- We can declare a dependency multiple times, and specify an `alias`:
  ```yaml
  dependencies:
    - name: redis
      version: '*'
      alias: querycache
    - name: redis
      version: '*'
      alias: celeryqueue
  ```

- `.Chart.Name` will be set to the `alias`

---

class: extra-details

## Determining if we're in a subchart

- `.Chart.IsRoot` indicates if we're in the top-level chart or in a sub-chart

- Useful in charts that are designed to be used standalone or as dependencies

- Example: generic chart

  - when used standalone (`.Chart.IsRoot` is `true`), use `.Release.Name`

  - when used as a subchart e.g. with multiple aliases, use `.Chart.Name`

???

:EN:- Depending on other charts
:EN:- Charts within charts

:FR:- Dépendances entre charts
:FR:- Un chart peut en cacher un autre
