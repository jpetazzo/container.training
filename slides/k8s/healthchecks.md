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

- If the liveness probe fails *N* consecutive times, the container is killed

- *N* is the `failureThreshold` (3 by default)

---

## Readiness probe

- Indicates if the container is ready to serve traffic

- If a container becomes "unready" (let's say busy!) it might be ready again soon

- If the readiness probe fails:

  - the container is *not* killed

  - if the pod is a member of a service, it is temporarily removed

  - it is re-added as soon as the readiness probe passes again

---

## When to use a readiness probe

- To indicate temporary failures

  - the application can only service *N* parallel connections

  - the runtime is busy doing garbage collection or initial data load

- The container is marked as "not ready" after `failureThreshold` failed attempts

  (3 by default)

- It is marked again as "ready" after `successThreshold` successful attempts

  (1 by default)

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

- Containers in a broken state gets killed and restarted

  (instead of serving errors or timeouts)

- Overloaded backends get removed from load balancer rotation

  (thus improving response times across the board)

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

## Details about liveness and readiness probes

- Probes are executed at intervals of `periodSeconds` (default: 10)

- The timeout for a probe is set with `timeoutSeconds` (default: 1)

- A probe is considered successful after `successThreshold` successes (default: 1)

- A probe is considered failing after `failureThreshold` failures (default: 3)

- If a probe is not defined, it's as if there was an "always successful" probe
