# Getting started with Bento

How can we move to a message queue architecture...

*...without rewriting a bunch of code?*

🤔

---

## Bento

https://bento.dev/

"Fancy stream processing made operationally mundane"

"Written in Go, deployed as a static binary, declarative configuration. Open source and cloud native as utter heck."

With ✨ amazing ✨ documentation 😍

---

class: extra-details

## Tiny bit of history

- Original project: Benthos

- May 30, 2024: [Redpanda acquires Benthos][redpanda-acquires-benthos]

  - Benthos is now Redpanda Connect

  - some parts have been relicensed as commercial products

- May 31, 2024: [Warpstream forks Benthos][warpstream-forks-benthos]

  - that fork is named "Bento"

  - it's fully open source

- We're going to use Bento here, but Redpanda Connect should work fine too!

---

## Bento concepts

- Message stream processor

- Each pipeline is configured by a YAML configuration that defines:

  - input (where do we get the messages?)

  - pipeline (optional: how do we transform the messages?)

  - output (where do we put the messages afterwards?)

- Once Bento is started, it runs the pipelines forever

  (except for pipelines that have a logical end, e.g. reading from a file)

- Embedded language (Bloblang) to manipulate/transform messages

---

## Messages

- Typically JSON objects

  (but raw strings are also possible)

- Nesting, arrays, etc. are OK

---

## Getting started with Bento

We're going to:

1. Import a bunch of cities from a CSV file into a Redis queue.

2. Read back these cities using a web server.

3. Use an "enrichment workflow" to query our LLM for each city.

---

## 1️⃣ Importing cities

Let's break down the work:

- download the data set

- create the Bento configuration

- deploy Redis

- start Bento

---

## Downloading the data set

- Example database:

  https://www.kaggle.com/datasets/juanmah/world-cities

- Let's download and uncompress the data set:
  ```bash
  curl -fsSL https://www.kaggle.com/api/v1/datasets/download/juanmah/world-cities |
    funzip > cities.csv
  ```

  (Ignore the "length error", it's harmless!)

- Check the structure of the data set:
  ```bash
  head cities.csv
  ```

---

## Creating the Bento configuration

- We need to find which `input` and `output` to use

- Check the list with `bento list` or the [documentation][bento-inputs]

- Then run `bento create INPUTNAME/PIPELINENAME/OUTPUTNAME`

- Generate a configuration file:
  ```bash
  bento create csv//redis_list > csv2redis.yaml
  ```

- Edit that configuration file; look for the `(required)` parameters

  (Everything else can go away!)

---

## Resulting configuration

If we trim all the default values, here is the result:

```yaml
input:
  csv:
    paths: ["cities.csv"]
output:
  redis_list:
    url: redis://redis:6379 # No default (required)
    key: cities
```

We'll call that value `csv2redis.yaml`.

---

## Deploying Redis

- Create a Deployment:
  ```bash
  kubectl create deployment redis --image redis
  ```

- Expose it:
  ```bash
  kubectl expose deployment redis --port 6379
  ```

---

## Starting Bento

Option 1: run it manually in a pod, to see what's going on.

```bash
bento --config csv2redis.yaml
```

Option 2: run it with e.g. the Bento Helm chart.

*We're not going to do that yet, since this particular pipeline has a logical end.*

*(The Helm chart is best suited to pipelines that run forever.)*

---

## Expected output

.small[
```
INFO Running main config from specified file       @service=bento bento_version="" path=csv2redis.yaml
INFO Launching a Bento instance, use CTRL+C to close  @service=bento
INFO Listening for HTTP requests at: http://0.0.0.0:4195  @service=bento
INFO Input type csv is now active                  @service=bento label="" path=root.input
INFO Output type redis_list is now active          @service=bento label="" path=root.output
INFO Pipeline has terminated. Shutting down the service  @service=bento
```
]

The pipeline should complete in just a few seconds.

---

## Checking what's in Redis

- Connect to our Redis instance:
  ```bash
  redis-cli -h redis
  ```

- List keys:
  ```redis
  KEYS *
  ```

- Check that the `cities` list has approx. 47000 elements:
  ```redis
  LLEN cities
  ```

- Get the first element of the list:
  ```redis
  LINDEX cities 0
  ```

---

## Fun with Bloblang

- Let's add a filter to keep only cities with a population above 10,000,000

- Add the following block to the Bento configuration:

```yaml
pipeline:
  processors:
    - switch:
        - check: this.population == ""
          processors:
            - mapping: root = deleted()
        - check: this.population.int64() < 10000000
          processors:
            - mapping: root = deleted()
```

(See the [docs][bento-switch] for details about the `switch` processor.)

---

## Testing our processor

- First, delete the existing `cities` list:
  ```bash
  redis-cli -h redis DEL cities
  ```

- Then, run the Bento pipeline again:
  ```bash
  bento --config csv2redis.yaml
  ```
  (It should complain about a few cities where the population has a decimal point.)

- Check how many cities were loaded:
  ```bash
  redis-cli -h redis LLEN cities
  ```
  (There should be 47.)

---

## 2️⃣ Consume the queue over HTTP

- We want to "get the next city" in the queue with a simple `curl`

- Our input will be `redis_list`

- Our output will be `http_server`

---

## 🏗️ Let's generate the Bento configuration!

Option 1: `bento create redis_list//http_server`

Option 2: [read the docs][output-http-server]

⚠️ Spoilers on next slide!

---

## `redis2http.yaml`

```yaml
input:
  redis_list:
    url: redis://redis:`6379`
    key: cities
output:
  http_server:
    path: /nextcity
```

This will set up an HTTP route to fetch *one* city.

It's also possible to batch, stream...

⚠️ As of November 2024, `bento create` uses port 6397 instead of 6379 for Redis!

---

## Trying it out

- Run Bento with this configuration:
  ```bash
  bento --config redis2http.yaml &
  ```

- Retrieve one city:
  ```bash
  curl http://localhost:4195/nextcity
  ```

- Check what happens after we retrive *all* the cities!
