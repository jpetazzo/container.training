# Running our first containers on Kubernetes

- First things first: we cannot run a container

--

- We are going to run a pod, and in that pod there will be a single container

--

- In that container in the pod, we are going to run a simple `ping` command

---

class: extra-details

## If you're running Kubernetes 1.17 (or older)...

- This material assumes that you're running a recent version of Kubernetes

  (at least 1.19) <!-- ##VERSION## -->

- You can check your version number with `kubectl version`

  (look at the server part)

- In Kubernetes 1.17 and older, `kubectl run` creates a Deployment

- If you're running such an old version:

  - it's obsolete and no longer maintained

  - Kubernetes 1.17 is [EOL since January 2021][nonactive]

  - **upgrade NOW!**

[nonactive]: https://kubernetes.io/releases/patch-releases/#non-active-branch-history

---

## Starting a simple pod with `kubectl run`

- `kubectl run` is convenient to start a single pod

- We need to specify at least a *name* and the image we want to use

- Optionally, we can specify the command to run in the pod

.lab[

- Let's ping the address of `localhost`, the loopback interface:
  ```bash
  kubectl run pingpong --image alpine ping 127.0.0.1
  ```

<!-- ```hide kubectl wait pod --selector=run=pingpong --for condition=ready``` -->

]

The output tells us that a Pod was created:
```
pod/pingpong created
```

---

## Viewing container output

- Let's use the `kubectl logs` command

- It takes a Pod name as argument

- Unless specified otherwise, it will only show logs of the first container in the pod

  (Good thing there's only one in ours!)

.lab[

- View the result of our `ping` command:
  ```bash
  kubectl logs pingpong
  ```

]

---

## Streaming logs in real time

- Just like `docker logs`, `kubectl logs` supports convenient options:

  - `-f`/`--follow` to stream logs in real time (à la `tail -f`)

  - `--tail` to indicate how many lines you want to see (from the end)

  - `--since` to get logs only after a given timestamp

.lab[

- View the latest logs of our `ping` command:
  ```bash
  kubectl logs pingpong --tail 1 --follow
  ```

- Stop it with Ctrl-C

<!--
```wait seq=3```
```keys ^C```
-->

]

---

## Scaling our application

- `kubectl` gives us a simple command to scale a workload:

  `kubectl scale TYPE NAME --replicas=HOWMANY`

- Let's try it on our Pod, so that we have more Pods!

.lab[

- Try to scale the Pod:
  ```bash
  kubectl scale pod pingpong --replicas=3
  ```

]

🤔 We get the following error, what does that mean?

```
Error from server (NotFound): the server could not find the requested resource
```

---

## Scaling a Pod

- We cannot "scale a Pod"

  (that's not completely true; we could give it more CPU/RAM)

- If we want more Pods, we need to create more Pods

  (i.e. execute `kubectl run` multiple times)

- There must be a better way!

  (spoiler alert: yes, there is a better way!)

---

class: extra-details

## `NotFound`

- What's the meaning of that error?
  ```
  Error from server (NotFound): the server could not find the requested resource
  ```

- When we execute `kubectl scale THAT-RESOURCE --replicas=THAT-MANY`,
  <br/>
  it is like telling Kubernetes:

  *go to THAT-RESOURCE and set the scaling button to position THAT-MANY*

- Pods do not have a "scaling button"

- Try to execute the `kubectl scale pod` command with `-v6`

- We see a `PATCH` request to `/scale`: that's the "scaling button"

  (technically it's called a *subresource* of the Pod)

---

## Creating more pods

- We are going to create a ReplicaSet

  (= set of replicas = set of identical pods)

- In fact, we will create a Deployment, which itself will create a ReplicaSet

- Why so many layers? We'll explain that shortly, don't worry!

---

## Creating a Deployment running `ping`

- Let's create a Deployment instead of a single Pod

.lab[

- Create the Deployment; pay attention to the `--`:
  ```bash
  kubectl create deployment pingpong --image=alpine -- ping 127.0.0.1
  ```

]

- The `--` is used to separate:

  - "options/flags of `kubectl create`

  - command to run in the container

---

## What has been created?

.lab[

<!-- ```hide kubectl wait pod --selector=app=pingpong --for condition=ready ``` -->

- Check the resources that were created:
  ```bash
  kubectl get all
  ```

]

Note: `kubectl get all` is a lie. It doesn't show everything.

(But it shows a lot of "usual suspects", i.e. commonly used resources.)

---

## There's a lot going on here!

```
NAME                            READY   STATUS        RESTARTS   AGE
pod/pingpong                    1/1     Running       0          4m17s
pod/pingpong-6ccbc77f68-kmgfn   1/1     Running       0          11s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3h45

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pingpong   1/1     1            1           11s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/pingpong-6ccbc77f68   1         1         1       11s
```

Our new Pod is not named `pingpong`, but `pingpong-xxxxxxxxxxx-yyyyy`.

We have a Deployment named `pingpong`, and an extra ReplicaSet, too. What's going on?

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

- Pods cannot be scaled horizontally

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

## Can we scale now?

- Let's try `kubectl scale` again, but on the Deployment!

.lab[

- Scale our `pingpong` deployment:
  ```bash
  kubectl scale deployment pingpong --replicas 3
  ```

- Note that we could also write it like this:
  ```bash
  kubectl scale deployment/pingpong --replicas 3
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

## Checking Deployment logs

- `kubectl logs` needs a Pod name

- But it can also work with a *type/name*

  (e.g. `deployment/pingpong`)

.lab[

- View the result of our `ping` command:
  ```bash
  kubectl logs deploy/pingpong --tail 2
  ```

]

- It shows us the logs of the first Pod of the Deployment

- We'll see later how to get the logs of *all* the Pods!

---

## Resilience

- The *deployment* `pingpong` watches its *replica set*

- The *replica set* ensures that the right number of *pods* are running

- What happens if pods disappear?

.lab[

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

## Deleting a standalone Pod

- What happens if we delete a standalone Pod?
 
  (like the first `pingpong` Pod that we created)

.lab[

- Delete the Pod:
  ```bash
  kubectl delete pod pingpong
  ```

<!--
```key ^D```
```key ^C```
-->

]

- No replacement Pod gets created because there is no *controller* watching it

- That's why we will rarely use standalone Pods in practice

  (except for e.g. punctual debugging or executing a short supervised task)

???

:EN:- Running pods and deployments
:FR:- Créer un pod et un déploiement
