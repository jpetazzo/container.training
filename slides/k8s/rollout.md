# Rolling updates

- By default (without rolling updates), when a scaled resource is updated:

  - new pods are created

  - old pods are terminated

  - ... all at the same time

  - if something goes wrong, ¯\\\_(ツ)\_/¯

---

## Rolling updates

- With rolling updates, when a resource is updated, it happens progressively

- Two parameters determine the pace of the rollout: `maxUnavailable` and `maxSurge`

- They can be specified in absolute number of pods, or percentage of the `replicas` count

- At any given time ...

  - there will always be at least `replicas`-`maxUnavailable` pods available

  - there will never be more than `replicas`+`maxSurge` pods in total

  - there will therefore be up to `maxUnavailable`+`maxSurge` pods being updated

- We have the possibility of rolling back to the previous version
  <br/>(if the update fails or is unsatisfactory in any way)

---

## Checking current rollout parameters

- Recall how we build custom reports with `kubectl` and `jq`:

.exercise[

- Show the rollout plan for our deployments:
  ```bash
    kubectl get deploy -o json |
            jq ".items[] | {name:.metadata.name} + .spec.strategy.rollingUpdate"
  ```

]

---

## Rolling updates in practice

- As of Kubernetes 1.8, we can do rolling updates with:

  `deployments`, `daemonsets`, `statefulsets`

- Editing one of these resources will automatically result in a rolling update

- Rolling updates can be monitored with the `kubectl rollout` subcommand

---

## Rolling out the new `worker` service

.exercise[

- Let's monitor what's going on by opening a few terminals, and run:
  ```bash
  kubectl get pods -w
  kubectl get replicasets -w
  kubectl get deployments -w
  ```

<!--
```wait NAME```
```keys ^C```
-->

- Update `worker` either with `kubectl edit`, or by running:
  ```bash
  kubectl set image deploy worker worker=dockercoins/worker:v0.2
  ```

]

--

That rollout should be pretty quick. What shows in the web UI?

---

## Give it some time

- At first, it looks like nothing is happening (the graph remains at the same level)

- According to `kubectl get deploy -w`, the `deployment` was updated really quickly

- But `kubectl get pods -w` tells a different story

- The old `pods` are still here, and they stay in `Terminating` state for a while

- Eventually, they are terminated; and then the graph decreases significantly

- This delay is due to the fact that our worker doesn't handle signals

- Kubernetes sends a "polite" shutdown request to the worker, which ignores it

- After a grace period, Kubernetes gets impatient and kills the container

  (The grace period is 30 seconds, but [can be changed](https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods) if needed)

---

## Rolling out something invalid

- What happens if we make a mistake?

.exercise[

- Update `worker` by specifying a non-existent image:
  ```bash
  kubectl set image deploy worker worker=dockercoins/worker:v0.3
  ```

- Check what's going on:
  ```bash
  kubectl rollout status deploy worker
  ```

<!--
```wait Waiting for deployment```
```keys ^C```
-->

]

--

Our rollout is stuck. However, the app is not dead.

(After a minute, it will stabilize to be 20-25% slower.)

---

## What's going on with our rollout?

- Why is our app a bit slower?

- Because `MaxUnavailable=25%`

  ... So the rollout terminated 2 replicas out of 10 available

- Okay, but why do we see 5 new replicas being rolled out?

- Because `MaxSurge=25%`

  ... So in addition to replacing 2 replicas, the rollout is also starting 3 more

- It rounded down the number of MaxUnavailable pods conservatively,
  <br/>
  but the total number of pods being rolled out is allowed to be 25+25=50%

---

class: extra-details

## The nitty-gritty details

- We start with 10 pods running for the `worker` deployment

- Current settings: MaxUnavailable=25% and MaxSurge=25%

- When we start the rollout:

  - two replicas are taken down (as per MaxUnavailable=25%)
  - two others are created (with the new version) to replace them
  - three others are created (with the new version) per MaxSurge=25%)

- Now we have 8 replicas up and running, and 5 being deployed

- Our rollout is stuck at this point!

---

## Checking the dashboard during the bad rollout

If you didn't deploy the Kubernetes dashboard earlier, just skip this slide.

.exercise[

- Connect to the dashboard that we deployed earlier

- Check that we have failures in Deployments, Pods, and Replica Sets

- Can we see the reason for the failure?

]

---

## Recovering from a bad rollout

- We could push some `v0.3` image

  (the pod retry logic will eventually catch it and the rollout will proceed)

- Or we could invoke a manual rollback

.exercise[

<!--
```keys
^C
```
-->

- Cancel the deployment and wait for the dust to settle:
  ```bash
  kubectl rollout undo deploy worker
  kubectl rollout status deploy worker
  ```

]

---

class: extra-details

## Changing rollout parameters

- We want to:

  - revert to `v0.1`
  - be conservative on availability (always have desired number of available workers)
  - go slow on rollout speed (update only one pod at a time) 
  - give some time to our workers to "warm up" before starting more

The corresponding changes can be expressed in the following YAML snippet:

.small[
```yaml
spec:
  template:
    spec:
      containers:
      - name: worker
        image: dockercoins/worker:v0.1
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  minReadySeconds: 10
```
]

---

class: extra-details

## Applying changes through a YAML patch

- We could use `kubectl edit deployment worker`

- But we could also use `kubectl patch` with the exact YAML shown before

.exercise[

.small[

- Apply all our changes and wait for them to take effect:
  ```bash
  kubectl patch deployment worker -p "
    spec:
      template:
        spec:
          containers:
          - name: worker
            image: dockercoins/worker:v0.1
      strategy:
        rollingUpdate:
          maxUnavailable: 0
          maxSurge: 1
      minReadySeconds: 10
    "
  kubectl rollout status deployment worker
  kubectl get deploy -o json worker |
          jq "{name:.metadata.name} + .spec.strategy.rollingUpdate"
  ```
  ] 

]
