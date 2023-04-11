# Healthchecks

- Healthchecks can improve the reliability of our applications, for instance:

  - detect when a container has crashed, and restart it automatically

  - pause a rolling update until the new containers are ready to serve traffic

  - temporarily remove an overloaded backend from a loadbalancer

- There are three kinds of healthchecks, corresponding to different use-cases:

  `startupProbe`, `readinessProbe`, `livenessProbe`

- Healthchecks are optional

  (in the absence of healthchecks, Kubernetes considers the container to be healthy)

---

## Use-cases in brief

1. *My container takes a long time to boot before being able to serve traffic.*

    → use a `startupProbe` (but often a `readinessProbe` can also do the job¹)

2. *Sometimes, my container is unavailable or overloaded, and needs to e.g. be taken temporarily out of load balancer rotation.*

    → use a `readinessProbe`

3. *Sometimes, my container enters a broken state which can only be fixed by a restart.*

    → use a `livenessProbe`

.footnote[¹In fact, we will see that in many cases, a `readinessProbe` is all we need. Stay tuned!]

---

## Startup probes

*My container takes a long time to boot before being able to serve traffic.*

- After creating a container, Kubernetes runs its startup probe

- The container will be considered "unhealthy" until the probe succeeds

- As long as the container is "unhealthy", its Pod...:

  - is not added to Services' endpoints

  - is not considered as "available" for rolling update purposes

- Readiness and liveness probes are enabled *after* startup probe reports success

  (if there is no startup probe, readiness and liveness probes are enabled right away)

---

## When to use a startup probe

- For containers that take a long time to start

  (more than 30 seconds)

- Especially if that time can vary a lot

  (e.g. fast in dev, slow in prod, or the other way around)

.footnote[⚠️ Make sure to read the warnings later in this section!]

---

## Readiness probes

*Sometimes, my container "needs a break".*

- Check if the container is ready or not

- If the container is not ready, its Pod is not ready

- If the Pod belongs to a Service, it is removed from its Endpoints

  (it stops receiving new connections but existing ones are not affected)

- If there is a rolling update in progress, it might pause

  (Kubernetes will try to respect the MaxUnavailable parameter)

- As soon as the readiness probe suceeds again, everything goes back to normal

---

## When to use a readiness probe

- To indicate failure due to an external cause

  - database is down or unreachable

  - mandatory auth or other backend service unavailable

- To indicate temporary failure or unavailability

  - runtime is busy doing garbage collection or (re)loading data

  - application can only service *N* parallel connections

  - new connections will be directed to other Pods

---

## Liveness probes

*This container is dead, we don't know how to fix it, other than restarting it.*

- Check if the container is dead or alive

- If Kubernetes determines that the container is dead:

  - it terminates the container gracefully

  - it restarts the container (unless the Pod's `restartPolicy` is `Never`)

- With the default parameters, it takes:

  - up to 30 seconds to determine that the container is dead

  - up to 30 seconds to terminate it

---

## When to use a liveness probe

- To detect failures that can't be recovered

  - deadlocks (causing all requests to time out)

  - internal corruption (causing all requests to error)

- Anything where our incident response would be "just restart/reboot it"

.footnote[⚠️ Make sure to read the warnings later in this section!]

---

## Different types of probes

- Kubernetes supports the following mechanisms:

  - `httpGet` (HTTP GET request)

  - `exec` (arbitrary program execution)

  - `tcpSocket` (check if a TCP port is accepting connections)

  - `grpc` (standard [GRPC Health Checking Protocol][grpc])

- All probes give binary results ("it works" or "it doesn't")

- Let's see the specific details for each of them!

[grpc]: https://grpc.github.io/grpc/core/md_doc_health-checking.html

---

## `httpGet`

- Make an HTTP GET request to the container

- The request will be made by Kubelet

  (doesn't require extra binaries in the container image)

- `port` must be specified

- `path` and extra `httpHeaders` can be specified optionally

- Kubernetes uses HTTP status code of the response:

  - 200-399 = success

  - anything else = failure

---

## `httpGet` example

The following readiness probe checks that the container responds on `/healthz`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  containers:
  - name: frontend
    image: myregistry.../frontend:v1.0
    readinessProbe:
      httpGet:
        port: 80
        path: /healthz
```

---

## `exec`

- Runs an arbitrary program *inside* the container

  (like with `kubectl exec` or `docker exec`)

- The program must be available in the container image

- Kubernetes uses the exit status of the program

  (standard UNIX convention: 0 = success, anything else = failure)

---

## `exec` example

When the worker is ready, it should create `/tmp/ready`.
<br/>
The following probe will give it 5 minutes to do so.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: queueworker
spec:
  containers:
  - name: worker
    image: myregistry.../worker:v1.0
    startupProbe:
      exec:
        command:
        - test
        - -f
        - /tmp/ready
      failureThreshold: 30
```

---

class: extra-details

## `startupProbe` and `failureThreshold`

- Note the `failureThreshold: 30` on the previous manifest

- This is important when defining a `startupProbe`

- Otherwise, if the container fails to come up within 30 seconds...

- ...Kubernetes restarts it!

- More on this later

---

## Using shell constructs

- If we want to use pipes, conditionals, etc. we should invoke a shell

- Example:
  ```yaml
    exec:
      command:
      - sh
      - -c
      - "curl http://localhost:5000/status | jq .ready | grep true"
  ```

- All these programs (`curl`, `jq`, `grep`) must be available in the container image

---

## `tcpSocket`

- Kubernetes checks if the indicated TCP port accepts connections

- There is no additional check

.warning[It's quite possible for a process to be broken, but still accept TCP connections!]

---

## `grpc`

<!-- ##VERSION## -->

<!-- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe -->

- Available in beta since Kubernetes 1.24

- Leverages standard [GRPC Health Checking Protocol][grpc]

[grpc]: https://grpc.github.io/grpc/core/md_doc_health-checking.html

---

## Timing and thresholds

- Probes are executed at intervals of `periodSeconds` (default: 10)

- The timeout for a probe is set with `timeoutSeconds` (default: 1)

.warning[If a probe takes longer than that, it is considered as a FAIL]

.warning[For liveness probes **and startup probes** this terminates and restarts the container]

- A probe is considered successful after `successThreshold` successes (default: 1)

- A probe is considered failing after `failureThreshold` failures (default: 3)

- All these parameters can be set independently for each probe

---

class: extra-details

## `initialDelaySeconds`

- A probe can have an `initialDelaySeconds` parameter (default: 0)

- Kubernetes will wait that amount of time before running the probe for the first time

- It is generally better to use a `startupProbe` instead

  (but this parameter did exist before startup probes were implemented)

---

## Be careful when adding healthchecks

- It is tempting to just "add all healthchecks"

- This can be counter-productive and cause problems:

  - cascading failures

  - containers that fail to start when system is under load

  - wasting resources by restarting big containers

- Let's analyze these problems!

---

## Liveness probes gotchas

.warning[**Do not** use liveness probes for problems that can't be fixed by a restart]

- Otherwise we just restart our pods for no reason, creating useless load

.warning[**Do not** depend on other services within a liveness probe]

- Otherwise we can experience cascading failures

  (example: web server liveness probe that makes a requests to a database)

.warning[**Make sure** that liveness probes respond quickly]

- The default probe timeout is 1 second (this can be tuned!)

- If the probe takes longer than that, it will eventually cause a restart

---

## Startup probes gotchas

- If a `startupProbe` fails, Kubernetes restarts the corresponding container

- In other words: with the default parameters, the container must start within 30 seconds

  (`failureThreshold` × `periodSeconds`)

- This is why we almost always want to adjust the parameters of a `startupProbe`

  (specifically, its `failureThreshold`)

- Sometimes, it's easier/simpler to use a `readinessProbe` instead

  (see next slide for details)

---

## When do we need startup probes?

- Only beneficial for containers that need a long time to start

  (more than 30 seconds)

- If there is no liveness probe, it's simpler to just use a readiness probe

  (since we probably want to have a readiness probe anyway)

- In other words, startup probes are useful in one situation:

  *we have a liveness probe, AND the container needs a lot of time to start*

- Don't forget to change the `failureThreshold`

  (otherwise the container will fail to start and be killed)

---

class: extra-details

## `readinessProbe` vs `startupProbe`

- A lot of blog posts / documentations / tutorials recommend readiness probes...

- ...even in scenarios where a startup probe would seem more appropriate!

- This is because startup probes are relatively recent

  (they reached GA status in Kubernetes 1.20)

- When there is no `livenessProbe`, using a `readinessProbe` is simpler:

  - a `startupProbe` generally requires to change the `failureThreshold`

  - a `startupProbe` generally also requires a `readinessProbe`

  - a single `readinessProbe` can fulfill both roles

---

## Best practices for healthchecks

- Readiness probes are almost always beneficial

  - don't hesitate to add them early!

  - we can even make them *mandatory*

- Be more careful with liveness and startup probes

  - they aren't always necessary

  - they can even cause harm

---

## Readiness probes

- Almost always beneficial

- Exceptions:

  - web service that doesn't have a dedicated "health" or "ping" route

  - ...and all requests are "expensive" (e.g. lots of external calls)

---

## Liveness probes

- If we're not careful, we end up restarting containers for no reason

  (which can cause additional load on the cluster, cascading failures, data loss, etc.)

- Suggestion:

  - don't add liveness probes immediately

  - wait until you have a bit of production experience with that code

  - then add narrow-scoped healthchecks to detect specific failure modes

- Readiness and liveness probes should be different

  (different check *or* different timeouts *or* different thresholds)

---

## Recap of the gotchas

- The default timeout is 1 second

  - if a probe takes longer than 1 second to reply, Kubernetes considers that it fails

  - this can be changed by setting the `timeoutSeconds` parameter
    <br/>(or refactoring the probe)

- Liveness probes should not be influenced by the state of external services

- Liveness probes and readiness probes should have different paramters

- For startup probes, remember to increase the `failureThreshold`

---

## Healthchecks for workers

(In that context, worker = process that doesn't accept connections)

- A relatively easy solution is to use files

- For a startup or readiness probe:

  - worker creates `/tmp/ready` when it's ready
  - probe checks the existence of `/tmp/ready`

- For a liveness probe:

  - worker touches `/tmp/alive` regularly
    <br/>(e.g. just before starting to work on a job)
  - probe checks that the timestamp on `/tmp/alive` is recent
  - if the timestamp is old, it means that the worker is stuck

- Sometimes it can also make sense to embed a web server in the worker

???

:EN:- Using healthchecks to improve availability
:FR:- Utiliser des *healthchecks* pour améliorer la disponibilité
