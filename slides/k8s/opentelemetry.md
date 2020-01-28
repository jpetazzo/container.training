# OpenTelemetry

*OpenTelemetry* is a "tracing" framework. It's a fusion of two other frameworks:
*opentracing* and *opencensus*.

The goal is to have deep integration with software languages and application framework to
enable deep dive tracing of different events accross different components

---
## Span ! span ! span !

- A unit a tracing is called a `span`.

- A span has a start time and and stop time and an ID.

- It represent an action that took some time to complete

    ex: call to function `B`, DB transation, REST call to a backend...

- A span could have a parent and could be parent of multiple child spans.

    ex: during the call to function `B`, a sub call to `C` and `D` has been issued

- Think of it as a "tree" of calls

---
## Distributed tracing

- This could be applied to multiple components

    ex: If microservice `A` send REST call to microservice `B`

    - `A` will have a span for the call to `B`
    - `B` will have a span for the call from `A`
       (that normally starts shortly after, and finishes shortly before)
    - the span of `A` will be the parent of the span of `B`,
       so that they join the same "tree" of call

details: `A` will send headers (depends of the protocol used) to tag the span ID,
so that `B` can generate child span and joining the same tree of call

---
## Centrally stored

- We do have "spans", ok. But what do we do with that ?

- We store them.

- In the previous exemple:

    - `A` will send trace to it's local agent
    - `B` will do the same
    - Every span will ends up in the same DB so that we can reconstruct the "tree" of call
      later on and analyze it.

- there is multiple implementation of those agents + DB + WebUI. The most famous opensource ones:

    - Zipkin
    - Jaeger

---
## Distributed sampled

- Huh, we store all of them ? (that could be a lot of storage)

- No, we could apply sampling, to reduce storage/network footprint.

- Smart sampling is applied directly in the application to save CPU if span is not needed.

- It also insures that if a span is mark as sampled, all child-span are sampled together

    (so that the tree of call is complete)
