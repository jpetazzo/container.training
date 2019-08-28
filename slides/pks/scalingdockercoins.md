# Scaling our demo app

- Our ultimate goal is to get more DockerCoins

  (i.e. increase the number of loops per second shown on the web UI)

- Let's look at the architecture again:

  ![DockerCoins architecture](images/dockercoins-diagram.svg)

- The loop is done in the worker;
  perhaps we could try adding more workers?

---

## Adding another worker

- All we have to do is scale the `worker` Deployment

.exercise[

- Open two new terminals to check what's going on with pods and deployments:
  ```bash
  kubectl get pods -w
  kubectl get deployments -w
  ```

<!--
```wait RESTARTS```
```keys ^C```
```wait AVAILABLE```
```keys ^C```
-->

- Now, create more `worker` replicas:
  ```bash
  kubectl scale deployment worker --replicas=2
  ```

]

After a few seconds, the graph in the web UI should show up.

---

## Adding more workers

- If 2 workers give us 2x speed, what about 3 workers?

.exercise[

- Scale the `worker` Deployment further:
  ```bash
  kubectl scale deployment worker --replicas=3
  ```

]

The graph in the web UI should go up again.

(This is looking great! We're gonna be RICH!)

---

## Adding even more workers

- Let's see if 10 workers give us 10x speed!

.exercise[

- Scale the `worker` Deployment to a bigger number:
  ```bash
  kubectl scale deployment worker --replicas=10
  ```

]

--

The graph will peak at 10 hashes/second.

(We can add as many workers as we want: we will never go past 10 hashes/second.)

---

class: extra-details

## Didn't we briefly exceed 10 hashes/second?

- It may *look like it*, because the web UI shows instant speed

- The instant speed can briefly exceed 10 hashes/second

- The average speed cannot

- The instant speed can be biased because of how it's computed

---

class: extra-details

## Why instant speed is misleading

- The instant speed is computed client-side by the web UI

- The web UI checks the hash counter once per second
  <br/>
  (and does a classic (h2-h1)/(t2-t1) speed computation)

- The counter is updated once per second by the workers

- These timings are not exact
  <br/>
  (e.g. the web UI check interval is client-side JavaScript)

- Sometimes, between two web UI counter measurements,
  <br/>
  the workers are able to update the counter *twice*

- During that cycle, the instant speed will appear to be much bigger
  <br/>
  (but it will be compensated by lower instant speed before and after)

---

## Why are we stuck at 10 hashes per second?

- If this was high-quality, production code, we would have instrumentation

  (Datadog, Honeycomb, New Relic, statsd, Sumologic, ...)

- It's not!

- Perhaps we could benchmark our web services?

  (with tools like `ab`, or even simpler, `httping`)

---

## Benchmarking our web services

- We want to check `hasher` and `rng`

- We are going to use `httping`

- It's just like `ping`, but using HTTP `GET` requests

  (it measures how long it takes to perform one `GET` request)

- It's used like this:
  ```
  httping [-c count] http://host:port/path
  ```

- Or even simpler:
  ```
  httping ip.ad.dr.ess
  ```

- We will use `httping` on the ClusterIP addresses of our services

---

## Running a debug pod

We don't have direct access to ClusterIP services, nor do we want to run a bunch of port-forwards. Instead we can run a Pod containing `httping` and then use `kubectl exec` to perform our debugging.

.excercise[

- Run a debug pod
  ```bash
  kubectl run debug --image=paulczar/debug \
    --restart=Never -- sleep 6000
  ```

]

--

This will run our debug pod which contains tools like `httping` that will self-destruct after 6000 seconds.

---

### Executing a command in a running pod

- You may have need to occasionally run a command inside a pod. Rather than trying to run `SSH` inside a container you can use the `kubectl exec` command.

.excercise[

  - Run curl inside your debug pod:
  ```bash
  kubectl exec debug -- curl -s https://google.com
  ```
]

--

```html
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="https://www.google.com/">here</A>.
</BODY></HTML>
```

---

## Service Discovery

- Each of our services has a Cluster IP which we could get using `kubectl get services`

- Or do it programmatically, like so:
  ```bash
  HASHER=$(kubectl get svc hasher -o go-template={{.spec.clusterIP}})
  RNG=$(kubectl get svc rng -o go-template={{.spec.clusterIP}})
  ```

- However Kubernetes has an in-cluster DNS server which means if you're inside the cluster you can simple use the service name as an endpoint.

---

## Checking `hasher` and `rng` response times

.exercise[

- Check the response times for both services:
  ```bash
  kubectl exec debug -- httping -c 3 hasher
  kubectl exec debug -- httping -c 3 rng
  ```

]

--

- `hasher` is fine (it should take a few milliseconds to reply)

- `rng` is not (it should take about 700 milliseconds if there are 10 workers)

- Something is wrong with `rng`, but ... what?
