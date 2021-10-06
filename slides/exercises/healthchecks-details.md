# Exercise - Healthchecks

- We want to add healthchecks to the `rng` service in dockercoins

- First, deploy a new copy of dockercoins

- Then, add a readiness probe on the `rng` service

  (using a simple HTTP check on the `/` route of the service)

- Check what happens when deploying an invalid image for `rng` (e.g. `alpine`)

- Then roll back `rng` to the original image and add a liveness probe

  (with the same parameters)

- Scale up the `worker` service (to 15+ workers) and observe

- What happens, and how can we improve the situation?

---

## Goal

- *Before* adding the readiness probe:

  updating the image of the `rng` service with `alpine` should break it

- *After* adding the readiness probe:

  updating the image of the `rng` service with `alpine` shouldn't break it

- When adding the liveness probe, nothing special should happen

- Scaling the `worker` service will then cause disruptions

- The final goal is to understand why, and how to fix it
