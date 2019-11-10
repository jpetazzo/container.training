## Adding healthchecks to an app

- Let's add healthchecks to DockerCoins!

- We will examine the questions of the previous slide

- Then we will review each component individually to add healthchecks

---

## Liveness, readiness, or both?

- To answer that question, we need to see the app run for a while

- Do we get temporary, recoverable glitches?

  → then use readiness

- Or do we get hard lock-ups requiring a restart?

  → then use liveness

- In the case of DockerCoins, we don't know yet!

- Let's pick liveness

---

## Do we have HTTP endpoints that we can use?

- Each of the 3 web services (hasher, rng, webui) has a trivial route on `/`

- These routes:

  - don't seem to perform anything complex or expensive

  - don't seem to call other services

- Perfect!

  (See next slides for individual details)

---

- [hasher.rb](https://github.com/jpetazzo/container.training/blob/master/dockercoins/hasher/hasher.rb)
  ```ruby
    get '/' do
      "HASHER running on #{Socket.gethostname}\n"
    end
  ```

- [rng.py](https://github.com/jpetazzo/container.training/blob/master/dockercoins/rng/rng.py)
  ```python
    @app.route("/")
    def index():
      return "RNG running on {}\n".format(hostname)
  ```

- [webui.js](https://github.com/jpetazzo/container.training/blob/master/dockercoins/webui/webui.js)
  ```javascript
    app.get('/', function (req, res) {
      res.redirect('/index.html');
    });
  ```

---

## Running DockerCoins

- We will run DockerCoins in a new, separate namespace

- We will use a set of YAML manifests and pre-built images

- We will add our new liveness probe to the YAML of the `rng` DaemonSet

- Then, we will deploy the application

---

## Creating a new namespace

- This will make sure that we don't collide / conflict with previous exercises

.exercise[

- Create the yellow namespace:
  ```bash
  kubectl create namespace yellow
  ```

- Switch to that namespace:
  ```bash
  kns yellow
  ```

]

---

## Retrieving DockerCoins manifests

- All the manifests that we need are on a convenient repository:

  https://github.com/jpetazzo/kubercoins

.exercise[

- Clone that repository:
  ```bash
  cd ~
  git clone https://github.com/jpetazzo/kubercoins
  ```

- Change directory to the repository:
  ```bash
  cd kubercoins
  ```

]

---

## A simple HTTP liveness probe

This is what our liveness probe should look like:

```yaml
containers:
- name: ...
image: ...
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 5
```

This will give 30 seconds to the service to start. (Way more than necessary!)
<br/>
It will run the probe every 5 seconds.
<br/>
It will use the default timeout (1 second).
<br/>
It will use the default failure threshold (3 failed attempts = dead).
<br/>
It will use the default success threshold (1 successful attempt = alive).

---

## Adding the liveness probe

- Let's add the liveness probe, then deploy DockerCoins

.exercise[

- Edit `rng-daemonset.yaml` and add the liveness probe
  ```bash
  vim rng-daemonset.yaml
  ```

- Load the YAML for all the resources of DockerCoins:
  ```bash
  kubectl apply -f .
  ```

]

---

## Testing the liveness probe

- The rng service needs 100ms to process a request

  (because it is single-threaded and sleeps 0.1s in each request)

- The probe timeout is set to 1 second

- If we send more than 10 requests per second per backend, it will break

- Let's generate traffic and see what happens!

.exercise[

- Get the ClusterIP address of the rng service:
  ```bash
  kubectl get svc rng
  ```

]

---

## Monitoring the rng service

- Each command below will show us what's happening on a different level

.exercise[

- In one window, monitor cluster events:
  ```bash
  kubectl get events -w
  ```

- In another window, monitor the response time of rng:
  ```bash
  httping `<ClusterIP>`
  ```

- In another window, monitor pods status:
  ```bash
  kubectl get pods -w
  ```

]

---

## Generating traffic

- Let's use `ab` to send concurrent requests to rng

.exercise[

- In yet another window, generate traffic:
  ```bash
  ab -c 10 -n 1000 http://`<ClusterIP>`/1
  ```

- Experiment with higher values of `-c` and see what happens

]

- The `-c` parameter indicates the number of concurrent requests

- The final `/1` is important to generate actual traffic

  (otherwise we would use the ping endpoint, which doesn't sleep 0.1s per request)

---

## Discussion

- Above a given threshold, the liveness probe starts failing

  (about 10 concurrent requests per backend should be plenty enough)

- When the liveness probe fails 3 times in a row, the container is restarted

- During the restart, there is *less* capacity available

- ... Meaning that the other backends are likely to timeout as well

- ... Eventually causing all backends to be restarted

- ... And each fresh backend gets restarted, too

- This goes on until the load goes down, or we add capacity

*This wouldn't be a good healthcheck in a real application!*

---

## Better healthchecks

- We need to make sure that the healthcheck doesn't trip when
  performance degrades due to external pressure

- Using a readiness check would have fewer effects

  (but it would still be an imperfect solution)

- A possible combination:

  - readiness check with a short timeout / low failure threshold

  - liveness check with a longer timeout / higher failure threshold

---

## Healthchecks for redis

- A liveness probe is enough

  (it's not useful to remove a backend from rotation when it's the only one)

- We could use an exec probe running `redis-cli ping`

---

class: extra-details

## Exec probes and zombies

- When using exec probes, we should make sure that we have a *zombie reaper*

  🤔🧐🧟 Wait, what?

- When a process terminates, its parent must call `wait()`/`waitpid()`

  (this is how the parent process retrieves the child's exit status)

- In the meantime, the process is in *zombie* state

  (the process state will show as `Z` in `ps`, `top` ...)

- When a process is killed, its children are *orphaned* and attached to PID 1

- PID 1 has the responsibility of *reaping* these processes when they terminate

- OK, but how does that affect us?

---

class: extra-details

## PID 1 in containers

- On ordinary systems, PID 1 (`/sbin/init`) has logic to reap processes

- In containers, PID 1 is typically our application process

  (e.g. Apache, the JVM, NGINX, Redis ...)

- These *do not* take care of reaping orphans

- If we use exec probes, we need to add a process reaper

- We can add [tini](https://github.com/krallin/tini) to our images

- Or [share the PID namespace between containers of a pod](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/)

  (and have gcr.io/pause take care of the reaping)

- Discussion of this in [Video - 10 Ways to Shoot Yourself in the Foot with Kubernetes, #9 Will Surprise You](https://www.youtube.com/watch?v=QKI-JRs2RIE)
