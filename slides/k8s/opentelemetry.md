# OpenTelemetry

*OpenTelemetry* is a "tracing" framework.

It's a fusion of two other frameworks:
*OpenTracing* and *OpenCensus*.

Its goal is to provide deep integration with programming languages and
application frameworks to enabled deep dive tracing of different events accross different components.

---

## Span ! span ! span !

- A unit of tracing is called a *span*

- A span has: a start time, a stop time, and an ID

- It represents an action that took some time to complete

  (e.g.: function call, database transaction, REST API call ...)

- A span can have a parent span, and can have multiple child spans

  (e.g.: when calling function `B`, sub-calls to `C` and `D` were issued)

- Think of it as a "tree" of calls

---

## Distributed tracing

- When two components interact, their spans can be connected together

- Example: microservice `A` sends a REST API call to microservice `B`

    - `A` will have a span for the call to `B`

    - `B` will have a span for the call from `A`
       <br/>(that normally starts shortly after, and finishes shortly before)

    - the span of `A` will be the parent of the span of `B`

    - they join the same "tree" of calls

<!-- FIXME the thing below? -->

details: `A` will send headers (depends of the protocol used) to tag the span ID,
so that `B` can generate child span and joining the same tree of call

---

## Centrally stored

- What do we do with all these spans?

- We store them!

- In the previous exemple:

    - `A` will send trace information to its local agent
    - `B` will do the same
    - every span will end up in the same DB
    - at a later point, we can reconstruct the "tree" of call and analyze it

- There are multiple implementations of this stack (agent + DB + web UI)

  (the most famous open source ones are Zipkin and Jaeger)

---

## Data sampling

- Do we store *all* the spans?

  (it looks like this could need a lot of storage!)

- No, we can use *sampling*, to reduce storage and network requirements

- Smart sampling is applied directly in the application to save CPU if span is not needed

- It also insures that if a span is marked as sampled, all child span are sampled as well

    (so that the tree of call is complete)
