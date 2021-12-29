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
        version: 11.0.5
        repository: https://charts.bitnami.com/bitnami
        condition: redis.enabled
  ```

]

Where do that `repository` and `version` come from?

We're assuming here that we did our reserach,
or that our resident Helm expert advised us to
use Bitnami's Redis chart.

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

  (e.g. "version 11.whatever, but below 12")

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
        version: ">=11, <12"
        repository: https://charts.bitnami.com/bitnami
  ```

- This makes sure that we have the most recent version in the 11.x train

- ... But without upgrading to version 12.x

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

## Dependency tuning

- DockerCoins expects the `redis` Service to be named `redis`

- Our Redis chart uses a different Service name by default

- Service name is `{{ template "redis.fullname" . }}-master`

- `redis.fullname` looks like this:
  ```
    {{- define "redis.fullname" -}}
    {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
    [...]
    {{- end }}
    {{- end }}
  ```

- How do we fix this?

---

## Setting dependency variables

- If we set `fullnameOverride` to `redis`:

  - the `{{ template ... }}` block will output `redis`

  - the Service name will be `redis-master`

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

class: extra-details

## Passing templates

- We can even pass template `{{ include "template.name" }}`, but warning:

   - need to be evaluated with the `tpl` function, on the child side

   - evaluated in the context of the child, with no access to parent variables

<!-- FIXME this probably deserves an example, but I can't imagine one right now 😅 -->

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

- Decompress the chart:
  ```yaml
  cd charts
  tar zxf redis-*.tgz
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

## Compatibility with Helm 2

- Chart `apiVersion: v1` is the only version supported by Helm 2

- Chart v1 is also supported by Helm 3

- Use v1 if you want to be compatible with Helm 2

- Instead of `Chart.yaml`, dependencies are defined in `requirements.yaml`

  (and we should commit `requirements.lock` instead of `Chart.lock`)

???

:EN:- Depending on other charts
:EN:- Charts within charts

:FR:- Dépendances entre charts
:FR:- Un chart peut en cacher un autre
