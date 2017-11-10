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

- Let's ping `goo.gl`:
  ```bash
  kubectl run pingpong --image alpine ping goo.gl
  ```

]

--

OK, what just happened?

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
- `deploy/pingpong` (the *deployment* that we just created)
- `rs/pingpong-xxxx` (a *replica set* created by the deployment)
- `po/pingpong-yyyy` (a *pod* created by the replica set)

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

- `kubectl run` created a *deployment*, `deploy/pingpong`

- That deployment created a *replica set*, `rs/pingpong-xxxx`

- That replica set created a *pod*, `po/pingpong-yyyy`

- We'll see later how these folks play together for:

  - scaling

  - high availability

  - rolling updates

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

<!--
```keys
^C
```
-->

]

---

## Scaling our application

- We can create additional copies of our container (I mean, our pod) with `kubectl scale`

.exercise[

- Scale our `pingpong` deployment:
  ```bash
  kubectl scale deploy/pingpong --replicas 8
  ```

]

Note: what if we tried to scale `rs/pingpong-xxxx`?

We could! But the *deployment* would notice it right away, and scale back to the initial level.

---

## Resilience

- The *deployment* `pingpong` watches its *replica set*

- The *replica set* ensures that the right number of *pods* are running

- What happens if pods disappear?

.exercise[

- In a separate window, list pods, and keep watching them:
  ```bash
  kubectl get pods -w
  ```

<!--
```keys
^C
```
-->

- Destroy a pod:
  ```bash
  kubectl delete pod pingpong-yyyy
  ```
]

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

Unfortunately, `--follow` cannot (yet) be used to stream the logs from multiple containers.

---

class: title

.small[
Meanwhile, at the Google NOC ...

.small[
Why the hell 
<br/>
are we getting 1000 packets per second 
<br/>
of ICMP ECHO traffic from EC2 ?!?
]
]
