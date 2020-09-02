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

  (at least, not in Kubernetes 1.18; but that changed in Kubernetes 1.19)

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

<!-- ```hide kubectl wait pod --selector=app=pingpong --for condition=ready ``` -->

]

---

class: extra-details

## In Kubernetes 1.19

- Since Kubernetes 1.19, we can specify the command to run

- The command must be passed after two dashes:
  ```bash
  kubectl create deployment pingpong --image=alpine -- ping 127.1
  ```

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

- Stop it with Ctrl-C

<!--
```wait seq=3```
```keys ^C```
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

- Check that we now have multiple pods:
  ```bash
  kubectl get pods
  ```

]

---

class: extra-details

## Scaling a Replica Set

- What if we scale the Replica Set instead of the Deployment?

- The Deployment would notice it right away and scale back to the initial level

- The Replica Set makes sure that we have the right numbers of Pods

- The Deployment makes sure that the Replica Set has the right size

  (conceptually, it delegates the management of the Pods to the Replica Set)

- This might seem weird (why this extra layer?) but will soon make sense

  (when we will look at how rolling updates work!)

---

## Streaming logs of multiple pods

- What happens if we try `kubectl logs` now that we have multiple pods?

.exercise[

  ```bash
  kubectl logs deploy/pingpong --tail 3
  ```

]

`kubectl logs` will warn us that multiple pods were found.

It is showing us only one of them.

We'll see later how to address that shortcoming.

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
```key ^C```
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

???

:EN:- Running pods and deployments
:FR:- Créer un pod et un déploiement
