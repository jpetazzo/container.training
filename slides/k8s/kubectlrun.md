# Running our first containers on Kubernetes

- First things first: we cannot run a container

--

- We are going to run a pod, and in that pod there will be a single container

--

- In that container in the pod, we are going to run a simple `ping` command

--

- Sounds simple enough, right?

--

- Except ... that the `kubectl run` command changed in Kubernetes 1.18!

- We'll explain what has changed, and why

---

## Choose your own adventure

- First, let's check which version of Kubernetes we're running

.exercise[

- Check our API server version:
  ```bash
  kubectl version
  ```

- Look at the **Server Version** in the second part of the output

]

- In the following slides, we will talk about 1.17- or 1.18+

  (to indicate "up to Kubernetes 1.17" and "from Kubernetes 1.18")

---

## Starting a simple pod with `kubectl run`

- `kubectl run` is convenient to start a single pod

- We need to specify at least a *name* and the image we want to use

- Optionally, we can specify the command to run in the pod

.exercise[

- Let's ping the address of `localhost`, the loopback interface:
  ```bash
  kubectl run pingpong --image alpine ping 127.0.0.1
  ```

<!-- ```hide kubectl wait pod --selector=run=pingpong --for condition=ready``` -->

]

---

## What do we see?

- In Kubernetes 1.18+, the output tells us that a Pod is created:
  ```
  pod/pingpong created
  ```

- In Kubernetes 1.17-, the output is much more verbose:
  ```
  kubectl run --generator=deployment/apps.v1 is DEPRECATED 
  and will be removed in a future version. Use kubectl run 
  --generator=run-pod/v1 or kubectl create instead.
  deployment.apps/pingpong created
  ```

- There is a deprecation warning ...

- ... And a Deployment was created instead of a Pod

🤔 What does that mean?

---

## Show me all you got!

- What resources were created by `kubectl run`?

.exercise[

- Let's ask Kubernetes to show us *all* the resources:
  ```bash
  kubectl get all
  ```

]

Note: `kubectl get all` is a lie. It doesn't show everything.

(But it shows a lot of "usual suspects", i.e. commonly used resources.)

---

## The situation with Kubernetes 1.18+

```
NAME           READY   STATUS    RESTARTS   AGE
pod/pingpong   1/1     Running   0          9s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3h30m
```

We wanted a pod, we got a pod, named `pingpong`. Great!

(We can ignore `service/kubernetes`, it was already there before.)

---

## The situation with Kubernetes 1.17-

```
NAME                            READY   STATUS        RESTARTS   AGE
pod/pingpong-6ccbc77f68-kmgfn   1/1     Running       0          11s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3h45

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pingpong   1/1     1            1           11s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/pingpong-6ccbc77f68   1         1         1       11s
```

Our pod is not named `pingpong`, but `pingpong-xxxxxxxxxxx-yyyyy`.

We have a Deployment named `pingpong`, and an extra Replica Set, too. What's going on?

---

## From Deployment to Pod

We have the following resources:

- `deployment.apps/pingpong`

  This is the Deployment that we just created.

- `replicaset.apps/pingpong-xxxxxxxxxx`

  This is a Replica Set created by this Deployment.

- `pod/pingpong-xxxxxxxxxx-yyyyy`

  This is a *pod* created by the Replica Set.

Let's explain what these things are.

---

## Pod

- Can have one or multiple containers

- Runs on a single node

  (Pod cannot "straddle" multiple nodes)

- Pods cannot be moved

  (e.g. in case of node outage)

- Pods cannot be scaled

  (except by manually creating more Pods)

---

class: extra-details

## Pod details

- A Pod is not a process; it's an environment for containers

  - it cannot be "restarted"

  - it cannot "crash"

- The containers in a Pod can crash

- They may or may not get restarted

  (depending on Pod's restart policy)

- If all containers exit successfully, the Pod ends in "Succeeded" phase

- If some containers fail and don't get restarted, the Pod ends in "Failed" phase

---

## Replica Set

- Set of identical (replicated) Pods

- Defined by a pod template + number of desired replicas

- If there are not enough Pods, the Replica Set creates more

  (e.g. in case of node outage; or simply when scaling up)

- If there are too many Pods, the Replica Set deletes some

  (e.g. if a node was disconnected and comes back; or when scaling down)

- We can scale up/down a Replica Set

  - we update the manifest of the Replica Set

  - as a consequence, the Replica Set controller creates/deletes Pods

---

## Deployment

- Replica Sets control *identical* Pods

- Deployments are used to roll out different Pods

  (different image, command, environment variables, ...)

- When we update a Deployment with a new Pod definition:

  - a new Replica Set is created with the new Pod definition

  - that new Replica Set is progressively scaled up

  - meanwhile, the old Replica Set(s) is(are) scaled down

- This is a *rolling update*, minimizing application downtime

- When we scale up/down a Deployment, it scales up/down its Replica Set

---

## `kubectl run` through the ages

- When we want to run an app on Kubernetes, we *generally* want a Deployment

- Up to Kubernetes 1.17, `kubectl run` created a Deployment

  - it could also create other things, by using special flags

  - this was powerful, but potentially confusing

  - creating a single Pod was done with `kubectl run --restart=Never`

  - other resources could also be created with `kubectl create ...`

- From Kubernetes 1.18, `kubectl run` creates a Pod

  - other kinds of resources can still be created with `kubectl create`

---

## Creating a Deployment the proper way

- Let's destroy that `pingpong` app that we created

- Then we will use `kubectl create deployment` to re-create it

.exercise[

- On Kubernetes 1.18+, delete the Pod named `pingpong`:
  ```bash
  kubectl delete pod pingpong
  ```

- On Kubernetes 1.17-, delete the Deployment named `pingpong`:
  ```bash
  kubectl delete deployment pingpong
  ```

]

---

## Running `ping` in a Deployment

<!-- ##VERSION## -->

- When using `kubectl create deployment`, we cannot indicate the command to execute

  (at least, not in Kubernetes 1.18)

- We can:

  - write a custom YAML manifest for our Deployment

--

  - (yeah right ... too soon!)

--

  - use an image that has the command to execute baked in

  - (much easier!)

--

- We will use the image `jpetazzo/ping`

  (it has a default command of `ping 127.0.0.1`)

---

## Creating a Deployment running `ping`

- Let's create a Deployment named `pingpong`

- It will use the image `jpetazzo/ping`

.exercise[

- Create the Deployment:
  ```bash
  kubectl create deployment pingpong --image=jpetazzo/ping
  ```

- Check the resources that were created:
  ```bash
  kubectl get all
  ```

<!-- ```hide kubectl wait pod --selector=run=pingpong --for condition=ready ``` -->

]

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

<!--
```wait seq=3```
```tmux split-pane -h```
-->

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

<!--
```tmux last-pane```
```key ^C```
-->

- Restart it:
  ```bash
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

<!--
```wait using pod/pingpong-```
```tmux last-pane```
-->

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

<!--
```wait Every 2.0s```
```tmux split-pane -v```
-->

- Destroy the pod currently shown by `kubectl logs`:
  ```
  kubectl delete pod pingpong-xxxxxxxxxx-yyyyy
  ```

<!--
```tmux select-pane -t 0```
```copy pingpong-[^-]*-.....```
```tmux last-pane```
```keys kubectl delete pod ```
```paste```
```key ^J```
```check```
```key ^D```
```tmux select-pane -t 1```
```key ^C```
```key ^D```
-->

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

## Viewing logs of multiple pods

- When we specify a deployment name, only one single pod's logs are shown

- We can view the logs of multiple pods by specifying a *selector*

- A selector is a logic expression using *labels*

- If we check the pods created by the deployment, they all have the label `app=pingpong`

  (this is just a default label that gets added when using `kubectl create deployment`)

.exercise[

- View the last line of log from all pods with the `app=pingpong` label:
  ```bash
  kubectl logs -l app=pingpong --tail 1
  ```

]

---

### Streaming logs of multiple pods

- Can we stream the logs of all our `pingpong` pods?

.exercise[

- Combine `-l` and `-f` flags:
  ```bash
  kubectl logs -l app=pingpong --tail 1 -f
  ```

<!--
```wait seq=```
```key ^C```
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
  kubectl logs -l app=pingpong --tail 1 -f
  ```

<!-- ```wait error:``` -->

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

class: extra-details

## Party tricks involving IP addresses

- It is possible to specify an IP address with less than 4 bytes

  (example: `127.1`)

- Zeroes are then inserted in the middle

- As a result, `127.1` expands to `127.0.0.1`

- So we can `ping 127.1` to ping `localhost`!

(See [this blog post](https://ma.ttias.be/theres-more-than-one-way-to-write-an-ip-address/
) for more details.)

---

class: extra-details

## More party tricks with IP addresses

- We can also ping `1.1`

- `1.1` will expand to `1.0.0.1`

- This is one of the addresses of Cloudflare's
  [public DNS resolver](https://blog.cloudflare.com/announcing-1111/)

- This is a quick way to check connectivity

  (if we can reach 1.1, we probably have internet access)

---

## Creating other kinds of resources

- Deployments are great for stateless web apps

  (as well as workers that keep running forever)

- Jobs are great for "long" background work

  ("long" being at least minutes our hours)

- CronJobs are great to schedule Jobs at regular intervals

  (just like the classic UNIX `cron` daemon with its `crontab` files)

- Pods are great for one-off execution that we don't care about

  (because they don't get automatically restarted if something goes wrong)

---

## Creating a Job

- A Job will create a Pod

- If the Pod fails, the Job will create another one

- The Job will keep trying until:

  - either a Pod succeeds,

  - or we hit the *backoff limit* of the Job (default=6)

.exercise[

- Create a Job that has a 50% chance of success:
  ```bash
    kubectl create job flipcoin --image=alpine -- sh -c 'exit $(($RANDOM%2))' 
  ```

]

---

## Our Job in action

- Our Job will create a Pod named `flipcoin-xxxxx`

- If the Pod succeeds, the Job stops

- If the Pod fails, the Job creates another Pod

.exercise[

- Check the status of the Pod(s) created by the Job:
  ```bash
  kubectl get pods --selector=job-name=flipcoin
  ```

]

---

class: extra-details

## More advanced jobs

- We can specify a number of "completions" (default=1)

- This indicates how many times the Job must be executed

- We can specify the "parallelism" (default=1)

- This indicates how many Pods should be running in parallel

- These options cannot be specified with `kubectl create job`

  (we have to write our own YAML manifest to use them)

---

## Scheduling periodic background work

- A Cron Job is a Job that will be executed at specific intervals

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

- Careful: make sure that the job terminates!

  (The Cron Job will not hold if a previous job is still running)

.exercise[

- Create the Cron Job:
  ```bash
    kubectl create cronjob every3mins --schedule="*/3 * * * *" \
            --image=alpine -- sleep 10
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

class: extra-details

## What about `kubectl run` before v1.18?

- Creating a Deployment:

  `kubectl run`

- Creating a Pod:

  `kubectl run --restart=Never`

- Creating a Job:

  `kubectl run --restart=OnFailure`

- Creating a Cron Job:

  `kubectl run --restart=OnFailure --schedule=...`

*Avoid using these forms, as they are deprecated since Kubernetes 1.18!*

---

## Beyond `kubectl create`

- As hinted earlier, `kubectl create` doesn't always expose all options

  - can't express parallelism or completions of Jobs

  - can't express Pods with multiple containers

  - can't express healthchecks, resource limits

  - etc.

- `kubectl create` and `kubectl run` are *helpers* that generate YAML manifests

- If we write these manifests ourselves, we can use all features and options

- We'll see later how to do that!
