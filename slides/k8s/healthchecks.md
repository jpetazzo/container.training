# Healthchecks

- Kubernetes provides two kinds of healthchecks: liveness and readiness

- Healthchecks are *probes* that apply to *containers* (not to pods)

- Each container can have two (optional) probes:

  - liveness = is this container dead or alive?

  - readiness = is this container ready to serve traffic?

- Different probes are available (HTTP, TCP, program execution)

- Let's see the difference and how to use them!

---

## Liveness probe

- Indicates if the container is dead or alive

- A dead container cannot come back to life

- If the liveness probe fails, the container is killed

  (to make really sure that it's really dead; no zombies or undeads!)

- What happens next depends on the pod's `restartPolicy`:

  - `Never`: the container is not restarted

  - `OnFailure` or `Always`: the container is restarted

---

## When to use a liveness probe

- To indicate failures that can't be recovered

  - deadlocks (causing all requests to time out)

  - internal corruption (causing all requests to error)

- Anything where our incident response would be "just restart/reboot it"

.warning[**Do not** use liveness probes for problems that can't be fixed by a restart]

- Otherwise we just restart our pods for no reason, creating useless load

---

## Readiness probe

- Indicates if the container is ready to serve traffic

- If a container becomes "unready" it might be ready again soon

- If the readiness probe fails:

  - the container is *not* killed

  - if the pod is a member of a service, it is temporarily removed

  - it is re-added as soon as the readiness probe passes again

---

## When to use a readiness probe

- To indicate failure due to an external cause

  - database is down or unreachable

  - mandatory auth or other backend service unavailable

- To indicate temporary failure or unavailability

  - application can only service *N* parallel connections

  - runtime is busy doing garbage collection or initial data load

- For processes that take a long time to start

  (more on that later)

---

## Dependencies

- If a web server depends on a database to function, and the database is down:

  - the web server's liveness probe should succeed

  - the web server's readiness probe should fail

- Same thing for any hard dependency (without which the container can't work)

.warning[**Do not** fail liveness probes for problems that are external to the container]

---

## Timing and thresholds

- Probes are executed at intervals of `periodSeconds` (default: 10)

- The timeout for a probe is set with `timeoutSeconds` (default: 1)

.warning[If a probe takes longer than that, it is considered as a FAIL]

- A probe is considered successful after `successThreshold` successes (default: 1)

- A probe is considered failing after `failureThreshold` failures (default: 3)

- A probe can have an `initialDelaySeconds` parameter (default: 0)

- Kubernetes will wait that amount of time before running the probe for the first time

  (this is important to avoid killing services that take a long time to start)

---

class: extra-details

## Startup probe

- Kubernetes 1.16 introduces a third type of probe: `startupProbe`

  (it is in `alpha` in Kubernetes 1.16)

- It can be used to indicate "container not ready *yet*"

  - process is still starting

  - loading external data, priming caches

- Before Kubernetes 1.16, we had to use the `initialDelaySeconds` parameter

  (available for both liveness and readiness probes)

- `initialDelaySeconds` is a rigid delay (always wait X before running probes)

- `startupProbe` works better when a container start time can vary a lot

---

## Different types of probes

- HTTP request

  - specify URL of the request (and optional headers)

  - any status code between 200 and 399 indicates success

- TCP connection

  - the probe succeeds if the TCP port is open

- arbitrary exec

  - a command is executed in the container

  - exit status of zero indicates success

---

## Benefits of using probes

- Rolling updates proceed when containers are *actually ready*

  (as opposed to merely started)

- Containers in a broken state get killed and restarted

  (instead of serving errors or timeouts)

- Unavailable backends get removed from load balancer rotation

  (thus improving response times across the board)

- If a probe is not defined, it's as if there was an "always successful" probe

---

## Example: HTTP probe

Here is a pod template for the `rng` web service of the DockerCoins app:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rng-with-liveness
spec:
  containers:
  - name: rng
    image: dockercoins/rng:v0.1
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 1
```

If the backend serves an error, or takes longer than 1s, 3 times in a row, it gets killed.

---

## Example: exec probe

Here is a pod template for a Redis server:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-with-liveness
spec:
  containers:
  - name: redis
    image: redis
    livenessProbe:
      exec:
        command: ["redis-cli", "ping"]
```

If the Redis process becomes unresponsive, it will be killed.

---

## Questions to ask before adding healthchecks

- Do we want liveness, readiness, both?

  (sometimes, we can use the same check, but with different failure thresholds)

- Do we have existing HTTP endpoints that we can use?

- Do we need to add new endpoints, or perhaps use something else?

- Are our healthchecks likely to use resources and/or slow down the app?

- Do they depend on additional services?

  (this can be particularly tricky, see next slide)

---

## Healthchecks and dependencies

- Liveness checks should not be influenced by the state of external services

- All checks should reply quickly (by default, less than 1 second)

- Otherwise, they are considered to fail

- This might require to check the health of dependencies asynchronously

  (e.g. if a database or API might be healthy but still take more than
  1 second to reply, we should check the status asynchronously and report
  a cached status)

---

## Healthchecks for workers

(In that context, worker = process that doesn't accept connections)

- Readiness isn't useful

  (because workers aren't backends for a service)

- Liveness may help us restart a broken worker, but how can we check it?

- Embedding an HTTP server is a (potentially expensive) option

- Using a "lease" file can be relatively easy:

  - touch a file during each iteration of the main loop

  - check the timestamp of that file from an exec probe

- Writing logs (and checking them from the probe) also works

???

:EN:- Using healthchecks to improve availability
:FR:- Utiliser des *healthchecks* pour améliorer la disponibilité
