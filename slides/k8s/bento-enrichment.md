# Calling APIs from Bento

- We want to ask our LLM who's the mayor of each of these cities

- We'll use a prompt that will usually ensure a short answer

  (so that it's faster; we don't want to wait 30 seconds per city!)

- We'll test the prompt with the Ollama CLI

- Then we'll craft a proper HTTP API query

- Finally, we'll configure an [enrichment workflow][enrichment] in Bento

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

The [Bento documentation][enrichment] is really good!

We need to set up:

- a `branch` processor

- a `request_map` to transform the city into an Ollama request

- an `http` processor to submit the request to Ollama

- a `result_map` to transform the Ollama response

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

- The `branch` processor allows doing the processing "on the side"

- `request_map` and `result_map` transform the message before/after processing

- Then, the result is combined with the original message (the `city`)

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

## 🙋 Choose your own adventure

How should we address errors?

- Option 1: increase the timeout in the [http][bento-http] processor

- Option 2: use a [retry][bento-retry] processor in the pipeline

- Option 3: use a [reject_errored][bento-reject] output

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

[bento-http]: https://warpstreamlabs.github.io/bento/docs/components/processors/http/
[bento-inputs]: https://warpstreamlabs.github.io/bento/docs/components/inputs/about/
[bento-reject]: https://warpstreamlabs.github.io/bento/docs/components/outputs/reject_errored
[bento-retry]: https://warpstreamlabs.github.io/bento/docs/components/processors/retry
[bento-switch]: https://warpstreamlabs.github.io/bento/docs/components/processors/switch/
[enrichment]: https://warpstreamlabs.github.io/bento/cookbooks/enrichments/
[output-http-server]: https://warpstreamlabs.github.io/bento/docs/components/outputs/http_server
[redpanda-acquires-benthos]: https://www.redpanda.com/press/redpanda-acquires-benthos
[warpstream-forks-benthos]: https://www.warpstream.com/blog/announcing-bento-the-open-source-fork-of-the-project-formerly-known-as-benthos

