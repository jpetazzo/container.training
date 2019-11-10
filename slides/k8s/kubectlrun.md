# Running our first containers on Kubernetes

- First things first: we cannot run a container

--

- We are going to run a pod, and in that pod there will be a single container

--

- In that container in the pod, we are going to run a simple `ping` command

- Then we are going to start additional copies of the pod

---

## Starting a simple pod with `kubectl run`

- We need to specify at least a *name* and the image we want to use

.exercise[

- Let's ping `1.1.1.1`, Cloudflare's 
  [public DNS resolver](https://blog.cloudflare.com/announcing-1111/):
  ```bash
  kubectl run pingpong --image alpine ping 1.1.1.1
  ```

<!-- ```hide kubectl wait deploy/pingpong --for condition=available``` -->

]

--

(Starting with Kubernetes 1.12, we get a message telling us that
`kubectl run` is deprecated. Let's ignore it for now.)

---

## Behind the scenes of `kubectl run`

- Let's look at the resources that were created by `kubectl run`

.exercise[

- List most resource types:
  ```bash
  kubectl get all
  ```

]

--

We should see the following things:
- `deployment.apps/pingpong` (the *deployment* that we just created)
- `replicaset.apps/pingpong-xxxxxxxxxx` (a *replica set* created by the deployment)
- `pod/pingpong-xxxxxxxxxx-yyyyy` (a *pod* created by the replica set)

Note: as of 1.10.1, resource types are displayed in more detail.

---

## What are these different things?

- A *deployment* is a high-level construct

  - allows scaling, rolling updates, rollbacks

  - multiple deployments can be used together to implement a
    [canary deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

  - delegates pods management to *replica sets*

- A *replica set* is a low-level construct

  - makes sure that a given number of identical pods are running

  - allows scaling

  - rarely used directly

- A *replication controller* is the (deprecated) predecessor of a replica set

---

## Our `pingpong` deployment

- `kubectl run` created a *deployment*, `deployment.apps/pingpong`

```
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pingpong   1         1         1            1           10m
```

- That deployment created a *replica set*, `replicaset.apps/pingpong-xxxxxxxxxx`

```
NAME                                  DESIRED   CURRENT   READY     AGE
replicaset.apps/pingpong-7c8bbcd9bc   1         1         1         10m
```

- That replica set created a *pod*, `pod/pingpong-xxxxxxxxxx-yyyyy`

```
NAME                            READY     STATUS    RESTARTS   AGE
pod/pingpong-7c8bbcd9bc-6c9qz   1/1       Running   0          10m
```

- We'll see later how these folks play together for:

  - scaling, high availability, rolling updates

---

## Viewing container output

- Let's use the `kubectl logs` command

- We will pass either a *pod name*, or a *type/name*

  (E.g. if we specify a deployment or replica set, it will get the first pod in it)

- Unless specified otherwise, it will only show logs of the first container in the pod

  (Good thing there's only one in ours!)

.exercise[

- View the result of our `ping` command:
  ```bash
  kubectl logs deploy/pingpong
  ```

]

---

## Streaming logs in real time

- Just like `docker logs`, `kubectl logs` supports convenient options:

  - `-f`/`--follow` to stream logs in real time (à la `tail -f`)

  - `--tail` to indicate how many lines you want to see (from the end)

  - `--since` to get logs only after a given timestamp

.exercise[

- View the latest logs of our `ping` command:
  ```bash
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

- Leave that command running, so that we can keep an eye on these logs

]

---

## Scaling our application

- We can create additional copies of our container (I mean, our pod) with `kubectl scale`

.exercise[

- Scale our `pingpong` deployment:
  ```bash
  kubectl scale deploy/pingpong --replicas 3
  ```

- Note that this command does exactly the same thing:
  ```bash
  kubectl scale deployment pingpong --replicas 3
  ```

]

Note: what if we tried to scale `replicaset.apps/pingpong-xxxxxxxxxx`?

We could! But the *deployment* would notice it right away, and scale back to the initial level.

---

## Log streaming

- Let's look again at the output of `kubectl logs`

  (the one we started before scaling up)

- `kubectl logs` shows us one line per second

- We could expect 3 lines per second

  (since we should now have 3 pods running `ping`)

- Let's try to figure out what's happening!

---

## Streaming logs of multiple pods

- What happens if we restart `kubectl logs`?

.exercise[

- Interrupt `kubectl logs` (with Ctrl-C)

- Restart it:
  ```bash
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

]

`kubectl logs` will warn us that multiple pods were found, and that it's showing us only one of them.

Let's leave `kubectl logs` running while we keep exploring.

---


## Resilience

- The *deployment* `pingpong` watches its *replica set*

- The *replica set* ensures that the right number of *pods* are running

- What happens if pods disappear?

.exercise[

- In a separate window, watch the list of pods:
  ```bash
  watch kubectl get pods
  ```

- Destroy the pod currently shown by `kubectl logs`:
  ```
  kubectl delete pod pingpong-xxxxxxxxxx-yyyyy
  ```
]

---

## What happened?

- `kubectl delete pod` terminates the pod gracefully

  (sending it the TERM signal and waiting for it to shutdown)

- As soon as the pod is in "Terminating" state, the Replica Set replaces it

- But we can still see the output of the "Terminating" pod in `kubectl logs`

- Until 30 seconds later, when the grace period expires

- The pod is then killed, and `kubectl logs` exits

---


## What if we wanted something different?

- What if we wanted to start a "one-shot" container that *doesn't* get restarted?

- We could use `kubectl run --restart=OnFailure` or `kubectl run --restart=Never`

- These commands would create *jobs* or *pods* instead of *deployments*

- Under the hood, `kubectl run` invokes "generators" to create resource descriptions

- We could also write these resource descriptions ourselves (typically in YAML),
  <br/>and create them on the cluster with `kubectl apply -f` (discussed later)

- With `kubectl run --schedule=...`, we can also create *cronjobs*

---

## Scheduling periodic background work

- A Cron Job is a job that will be executed at specific intervals

  (the name comes from the traditional cronjobs executed by the UNIX crond)

- It requires a *schedule*, represented as five space-separated fields:

  - minute [0,59]
  - hour [0,23]
  - day of the month [1,31]
  - month of the year [1,12]
  - day of the week ([0,6] with 0=Sunday)

- `*` means "all valid values"; `/N` means "every N"

- Example: `*/3 * * * *` means "every three minutes"

---

## Creating a Cron Job

- Let's create a simple job to be executed every three minutes

- Cron Jobs need to terminate, otherwise they'd run forever

.exercise[

- Create the Cron Job:
  ```bash
  kubectl run --schedule="*/3 * * * *" --restart=OnFailure --image=alpine sleep 10
  ```

- Check the resource that was created:
  ```bash
  kubectl get cronjobs
  ```

]

---

## Cron Jobs in action

- At the specified schedule, the Cron Job will create a Job

- The Job will create a Pod

- The Job will make sure that the Pod completes

  (re-creating another one if it fails, for instance if its node fails)

.exercise[

- Check the Jobs that are created:
  ```bash
  kubectl get jobs
  ```

]

(It will take a few minutes before the first job is scheduled.)

---


## What about that deprecation warning?

- As we can see from the previous slide, `kubectl run` can do many things

- The exact type of resource created is not obvious

- To make things more explicit, it is better to use `kubectl create`:

  - `kubectl create deployment` to create a deployment

  - `kubectl create job` to create a job

  - `kubectl create cronjob` to run a job periodically
    <br/>(since Kubernetes 1.14)

- Eventually, `kubectl run` will be used only to start one-shot pods

  (see https://github.com/kubernetes/kubernetes/pull/68132)

---

## Various ways of creating resources

- `kubectl run` 

  - easy way to get started
  - versatile

- `kubectl create <resource>` 

  - explicit, but lacks some features
  - can't create a CronJob before Kubernetes 1.14
  - can't pass command-line arguments to deployments

- `kubectl create -f foo.yaml` or `kubectl apply -f foo.yaml`

  - all features are available
  - requires writing YAML

---

## Viewing logs of multiple pods

- When we specify a deployment name, only one single pod's logs are shown

- We can view the logs of multiple pods by specifying a *selector*

- A selector is a logic expression using *labels*

- Conveniently, when you `kubectl run somename`, the associated objects have a `run=somename` label

.exercise[

- View the last line of log from all pods with the `run=pingpong` label:
  ```bash
  kubectl logs -l run=pingpong --tail 1
  ```

]

---

### Streaming logs of multiple pods

- Can we stream the logs of all our `pingpong` pods?

.exercise[

- Combine `-l` and `-f` flags:
  ```bash
  kubectl logs -l run=pingpong --tail 1 -f
  ```

<!--
```wait seq=```
```keys ^C```
-->

]

*Note: combining `-l` and `-f` is only possible since Kubernetes 1.14!*

*Let's try to understand why ...*

---

class: extra-details

### Streaming logs of many pods

- Let's see what happens if we try to stream the logs for more than 5 pods

.exercise[

- Scale up our deployment:
  ```bash
  kubectl scale deployment pingpong --replicas=8
  ```

- Stream the logs:
  ```bash
  kubectl logs -l run=pingpong --tail 1 -f
  ```

]

We see a message like the following one:
```
error: you are attempting to follow 8 log streams,
but maximum allowed concurency is 5,
use --max-log-requests to increase the limit
```

---

class: extra-details

## Why can't we stream the logs of many pods?

- `kubectl` opens one connection to the API server per pod

- For each pod, the API server opens one extra connection to the corresponding kubelet

- If there are 1000 pods in our deployment, that's 1000 inbound + 1000 outbound connections on the API server

- This could easily put a lot of stress on the API server

- Prior Kubernetes 1.14, it was decided to *not* allow multiple connections

- From Kubernetes 1.14, it is allowed, but limited to 5 connections

  (this can be changed with `--max-log-requests`)

- For more details about the rationale, see
  [PR #67573](https://github.com/kubernetes/kubernetes/pull/67573)

---

## Shortcomings of `kubectl logs`

- We don't see which pod sent which log line

- If pods are restarted / replaced, the log stream stops

- If new pods are added, we don't see their logs

- To stream the logs of multiple pods, we need to write a selector

- There are external tools to address these shortcomings

  (e.g.: [Stern](https://github.com/wercker/stern))

---

class: extra-details

## `kubectl logs -l ... --tail N`

- If we run this with Kubernetes 1.12, the last command shows multiple lines

- This is a regression when `--tail` is used together with `-l`/`--selector`

- It always shows the last 10 lines of output for each container

  (instead of the number of lines specified on the command line)

- The problem was fixed in Kubernetes 1.13

*See [#70554](https://github.com/kubernetes/kubernetes/issues/70554) for details.*

---

## Aren't we flooding 1.1.1.1?

- If you're wondering this, good question!

- Don't worry, though:

  *APNIC's research group held the IP addresses 1.1.1.1 and 1.0.0.1. While the addresses were valid, so many people had entered them into various random systems that they were continuously overwhelmed by a flood of garbage traffic. APNIC wanted to study this garbage traffic but any time they'd tried to announce the IPs, the flood would overwhelm any conventional network.*

  (Source: https://blog.cloudflare.com/announcing-1111/)

- It's very unlikely that our concerted pings manage to produce
  even a modest blip at Cloudflare's NOC!
