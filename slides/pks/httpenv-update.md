# Rolling updates

- By default (without rolling updates), when a scaled resource is updated:

  - new pods are created

  - old pods are terminated

  - ... all at the same time

  - if something goes wrong, ¯\\\_(ツ)\_/¯

---

## Rolling updates

- With rolling updates, when a Deployment is updated, it happens progressively

- The Deployment controls multiple Replica Sets

- Each Replica Set is a group of identical Pods

  (with the same image, arguments, parameters ...)

- During the rolling update, we have at least two Replica Sets:

  - the "new" set (corresponding to the "target" version)

  - at least one "old" set

- We can have multiple "old" sets

  (if we start another update before the first one is done)

---

## Update strategy

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
```key ^C```
-->

- Update `httpenv` either with `kubectl edit`, or by running:
  ```bash
  kubectl set env -e "hello=world" deployment httpenv
  ```
]
--


Deployments treat environment variable changes as a upgrade. You should see the rollout occur.

---

## Verify rollout

- Remember our `httpenv` app prints out our env variables...

.exercise[

- get the IP of the service:
  ```bash
    IP=`kubectl get svc httpenv \
    -o jsonpath="{.status.loadBalancer.ingress[*].ip}"`
    echo $IP
  ```

- check the app now shows this new environment variable:

  ```bash
  curl $IP:8888
  ```
  or 
  ```bash
  curl -s $IP:8888 | jq .hello
  ```
]

--

"hello": "world"

---

## Rolling out something invalid

- What happens if we make a mistake?

.exercise[

- Update `httpenv` by specifying a non-existent image:
  ```bash
  kubectl set image deploy httpenv httpenv=not-a-real-image
  ```

- Check what's going on:
  ```bash
  kubectl rollout status deploy httpenv
  ```

<!--
```wait Waiting for deployment...```
```key ^C```
-->

]

--

Our rollout is stuck. However, the app is not dead.

---

## What's going on with our rollout?

- Let's look at our app:

.exercise[

  - Check our pods:
  ```bash
  kubectl get pods
  ```
]

--

We have 8 running pods, and 5 failing pods.

---

Why do we have 8 running pods? we should have 10

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

- We start with 10 pods running for the `httpenv` deployment

- Current settings: MaxUnavailable=25% and MaxSurge=25%

- When we start the rollout:

  - two replicas are taken down (as per MaxUnavailable=25%)
  - two others are created (with the new version) to replace them
  - three others are created (with the new version) per MaxSurge=25%)

- Now we have 8 replicas up and running, and 5 being deployed

- Our rollout is stuck at this point!

---

## Recovering from a bad rollout

- We could push the missing image to our registry

  (the pod retry logic will eventually catch it and the rollout will proceed)

- Or we could invoke a manual rollback

.exercise[

<!-- ```key ^C``` -->

- Cancel the deployment and wait for the dust to settle:
  ```bash
  kubectl rollout undo deploy httpenv
  kubectl rollout status deploy httpenv
  ```

]

---

## Rolling back to an older version

- We reverted to our original working image :)

- We have 10 replicas running again.

---

## Multiple "undos"

- What happens if we try `kubectl rollout undo` again?

.exercise[

- Try it:
  ```bash
  kubectl rollout undo deployment httpenv
  ```

- Check the web UI, the list of pods ...

]

🤔 That didn't work.

---

## Multiple "undos" don't work

- If we see successive versions as a stack:

  - `kubectl rollout undo` doesn't "pop" the last element from the stack

  - it copies the N-1th element to the top

- Multiple "undos" just swap back and forth between the last two versions!

.exercise[

- Go back to the original version again:
  ```bash
  kubectl rollout undo deployment httpenv
  ```
]

---

## Listing versions

- We can list successive versions of a Deployment with `kubectl rollout history`

.exercise[

- Look at our successive versions:
  ```bash
  kubectl rollout history deployment httpenv
  ```

]

We don't see *all* revisions.

We might see something like 1, 4, 5.

(Depending on how many "undos" we did before.)

---

## Explaining deployment revisions

- These revisions correspond to our Replica Sets

- This information is stored in the Replica Set annotations

.exercise[

- Check the annotations for our replica sets:
  ```bash
  kubectl describe replicasets -l app=httpenv | grep -A3 ^Annotations
  ```

]

---

class: extra-details

## What about the missing revisions?

- The missing revisions are stored in another annotation:

  `deployment.kubernetes.io/revision-history`

- These are not shown in `kubectl rollout history`

- We could easily reconstruct the full list with a script

  (if we wanted to!)

---

## Rolling back to an older version

- `kubectl rollout undo` can work with a revision number

.exercise[

- Roll back to the "known good" deployment version:
  ```bash
  kubectl rollout undo deployment httpenv --to-revision=1
  ```

- Check the web UI via curl again
  ```bash
  curl $IP:8888
  ```
--

the `hello world` environment variable has gone as we're right back to the original revision of our application.

]

---

## Cleanup

.exercise[

- Delete all of the deployments, services, and cronjobs:

  ```bash
  kubectl delete deployments,cronjobs,services --all
  ```

]

--

Using `--all` on a delete is really destructive, be very careful with it.
