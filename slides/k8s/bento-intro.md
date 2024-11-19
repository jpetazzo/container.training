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

[redpanda-acquires-benthos]: https://www.redpanda.com/press/redpanda-acquires-benthos
[warpstream-forks-benthos]: https://www.warpstream.com/blog/announcing-bento-the-open-source-fork-of-the-project-formerly-known-as-benthos

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

- Check the list with `bento list` or the [documentation]

- Then run `bento create INPUTNAME/PIPELINENAME/OUTPUTNAME`

- Generate a configuration file:
  ```bash
  bento create csv//redis_list > csv2redis.yaml
  ```

- Edit that configuration file; look for the `(required)` parameters

  (Everything else can go away!)

[documentation]: https://warpstreamlabs.github.io/bento/docs/components/inputs/about/

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

The pipeline should complete in a just a few seconds.

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

(See the [docs][switch-docs] for details about the `switch` processor.)

[switch-docs]: https://warpstreamlabs.github.io/bento/docs/components/processors/switch/

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

## Generate the Bento configuration

Option 1: `bento create redis_list//http_server`

Option 2: [read the docs][output-http-server]

[output-http-server]: https://warpstreamlabs.github.io/bento/docs/components/outputs/http_server

---

## 🙋 Choose your adventure

Do you want to try to write that configuration?

Or shall we see it right away?

--

⚠️ Spoilers on next slide!

---

## `redis2http.yaml`

```yaml
input:
  redis_list:
    url: redis://redis:6379
    key: cities
output:
  http_server:
    path: /nextcity
```

This will set up an HTTP route to fetch *one* city.

It's also possible to batch, stream...

---

## Trying it out

- Run Bento with that configuration:
  ```bash
  bento --config redis2http.yaml &
  ```

- Retrieve one city:
  ```bash
  curl http://localhost:4195/nextcity
  ```

- Check what happens after we retrive *all* the cities!

---

## 3️⃣ Query our LLM for each city

- We want to ask our LLM who's the mayor of each of these cities

- We'll use a prompt that will usually ensure a short answer

  (so that it's faster; we don't want to wait 30 seconds per city!)

- We'll test the prompt with the Ollama CLI

- Then we'll craft a proper HTTP API query

- Finally, we'll configure an [enrichment workflow][enrichment] in Bento

[enrichment]: https://warpstreamlabs.github.io/bento/cookbooks/enrichments/

---

## Test our prompt

Assuming that our earlier Ollama Deployment is still running:

```bash
kubectl exec deployment/ollama -- \
ollama run qwen2:1.5b "
Who is the mayor of San Francisco?
Just give the name by itself on a single line.
If you don't know, don't say anything.
"
```

---

## Turn the prompt into an HTTP API query

Note: to install `http` in an Alpine container, run `apk add httpie`.

```bash
http http://ollama.default:11434/api/generate \
model=qwen2:1.5b stream:=false prompt="
Who is the mayor of Paris?
Just give the name by itself on a single line.
If you don't know, don't say anything.
"
```

We get a JSON payload, and we want to use the `response` field.

---

## Configure an enrichment workflow

The [documentation][enrichment] is really good!

We need to set up:

- a `branch` processor

- a `request_map` to transform the city into an Ollama request

- an `http` processor to submit the request to Ollama

- a `result_map` to transform the Ollama response

[enrichment]: https://warpstreamlabs.github.io/bento/cookbooks/enrichments/

---

## Without the `branch` processor

<pre class="mermaid">
flowchart LR

  CITY["
    city: Paris
    country: France
    population: 1106000
    iso2: FR
    ...
    "]

  REQ["
    model: qwen2:1.5b
    stream: false
    prompt: Who is the mayor of Paris?
    "]

  REP["
    response: Anne Hidalgo
    eval_count: ...
    prompt_eval_count: ...
    (other ollama fields)
    "]

  CITY@{ shape: card}
  REQ@{ shape: card}
  REP@{ shape: card}

  style CITY text-align: left
  style REQ text-align: left
  style REP text-align: left

  mapping@{ shape: diam }
  http["http processor"]@{ shape: diam }

  CITY --> mapping --> REQ --> http --> REP
</pre>

- We transform the `city` into an Ollama request

- The `http` processor submits the request to Ollama

- The final output is the Ollama response

---

## With the `branch` processor

<pre class="mermaid">
flowchart LR

  CITY["
    city: Paris
    country: France
    population: 1106000
    iso2: FR
    ...
    "]

  REQ["
    model: qwen2:1.5b
    stream: false
    prompt: Who is the mayor of Paris?
    "]

  REP["
    response: Anne Hidalgo
    eval_count: ...
    prompt_eval_count: ...
    (other ollama fields)
    "]

  OUT["
    city: Paris
    country: France
    population: 1106000
    iso2: FR
    ...
    mayor: Anne Hidalgo
    "]

  CITY@{ shape: card}
  REQ@{ shape: card}
  REP@{ shape: card}
  OUT@{ shape: card}

  style CITY text-align: left
  style REQ text-align: left
  style REP text-align: left
  style OUT text-align: left

  branch@{ shape: diam }
  request_map@{ shape: diam }
  result_map@{ shape: diam }
  http["http processor"]@{ shape: diam }

  CITY --> branch
  branch --> result_map
  branch --> request_map
  request_map --> REQ
  REQ --> http
  http --> REP
  REP --> result_map
  result_map --> OUT
</pre>

- The `branch` processor allows to do the processing "on the side"

- `request_map` and `result_map` transform the message before/after processing

- Then, the result if combined with the original message (the `city`)

---

```yaml
input:
  csv:
    paths: ["cities.csv"]
pipeline:
  processors:
    - branch:
        request_map: |
          root.model = "qwen2:1.5b"
          root.stream = false
          root.prompt = (
            "Who is the mayor of %s? ".format(this.city) +
            "Just give the name by itself on a single line. " +
            "If you don't know, don't say anything."
            )
        processors:
          - http:
              url: http://ollama:11434/api/generate
              verb: POST
        result_map: |
          root.mayor = this.response
```

---

## Trying it out

- Save the YAML on the previous page into a configuration file

- Run Bento with that configuration file

- What happens?

--

🤔 We're seeing errors due to timeouts

```
ERRO HTTP request to 'http://ollama...' failed: http://ollama...:
Post "http://ollama...": context deadline exceeded
(Client.Timeout exceeded while awaiting headers)
```

---

## 🙋 Choose your adventure

How should we address errors?

- Option 1: increase the timeout in the [http][doc-http] processor

- Option 2: use a [retry][doc-retry] processor in the pipeline

- Option 3: use a [reject_errored][doc-reject] output

[doc-http]: https://warpstreamlabs.github.io/bento/docs/components/processors/http/
[doc-retry]: https://warpstreamlabs.github.io/bento/docs/components/processors/retry
[doc-reject]: https://warpstreamlabs.github.io/bento/docs/components/outputs/reject_errored

---

## 🏗️ Let's build something!

- We want to process 1000 cities with our LLM

  (guessing who the mayor is, or something similar)

- Store the output wherever we want

  (Redis, CSV file, JSONL files...)

- Deal correctly with errors

  (we'll check that there are, indeed, 1000 cities in the output)

- Scale out to process faster

  (scale ollama to e.g. 10 replicas, enable parallelism in Bento)

---

class: title

🍱 Lunch time! 🍱

---

## What happened?

- If your Ollama pods have *resource requests*:

  → your cluster may have auto-scaled

- If your Ollama pods don't have *resource requests*:

  → you probably have a bunch of container restarts, due to out-of-memory errors

🤔 What's that about?

