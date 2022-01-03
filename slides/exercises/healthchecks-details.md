# Exercise — Healthchecks

- We want to add healthchecks to the `rng` service in dockercoins

- The `rng` service exhibits an interesting behavior under load:

  *its latency increases (which will cause probes to time out!)*

- We want to see:

  - what happens when the readiness probe fails

  - what happens when the liveness probe fails

  - how to set "appropriate" probes and probe parameters

---

## Setup

- First, deploy a new copy of dockercoins

  (for instance, in a brand new namespace)

- Pro tip #1: ping (e.g. with `httping`) the `rng` service at all times

  - it should initially show a few milliseconds latency

  - that will increase when we scale up

  - it will also let us detect when the service goes "boom"

- Pro tip #2: also keep an eye on the web UI

---

## Readiness

- Add a readiness probe to `rng`

  - this requires editing the pod template in the Deployment manifest

  - use a simple HTTP check on the `/` route of the service

  - keep all other parameters (timeouts, thresholds...) at their default values

- Check what happens when deploying an invalid image for `rng` (e.g. `alpine`)

*(If the probe was set up correctly, the app will continue to work,
because Kubernetes won't switch over the traffic to the `alpine` containers,
because they don't pass the readiness probe.)*

---

## Readiness under load

- Then roll back `rng` to the original image

- Check what happens when we scale up the `worker` Deployment to 15+ workers

  (get the latency above 1 second)

*(We should now observe intermittent unavailability of the service, i.e. every
30 seconds it will be unreachable for a bit, then come back, then go away again, etc.)*

---

## Liveness

- Now replace the readiness probe with a liveness probe

- What happens now?

*(At first the behavior looks the same as with the readiness probe:
service becomes unreachable, then reachable again, etc.; but there is
a significant difference behind the scenes. What is it?)*

---

## Readiness and liveness

- Bonus questions!

- What happens if we enable both probes at the same time?

- What strategies can we use so that both probes are useful?
