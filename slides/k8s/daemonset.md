# Daemon sets

- We want to scale `rng` in a way that is different from how we scaled `worker`

- We want one (and exactly one) instance of `rng` per node

- We *do not want* two instances of `rng` on the same node

- We will do that with a *daemon set*

---

## Why not a deployment?

- Can't we just do `kubectl scale deployment rng --replicas=...`?

--

- Nothing guarantees that the `rng` containers will be distributed evenly

- If we add nodes later, they will not automatically run a copy of `rng`

- If we remove (or reboot) a node, one `rng` container will restart elsewhere

  (and we will end up with two instances `rng` on the same node)

- By contrast, a daemon set will start one pod per node and keep it that way

  (as nodes are added or removed)

---

## Daemon sets in practice

- Daemon sets are great for cluster-wide, per-node processes:

  - `kube-proxy`

  - `weave` (our overlay network)

  - monitoring agents

  - hardware management tools (e.g. SCSI/FC HBA agents)

  - etc.

- They can also be restricted to run [only on some nodes](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#running-pods-on-only-some-nodes)

---

## Creating a daemon set

<!-- ##VERSION## -->

- Unfortunately, as of Kubernetes 1.19, the CLI cannot create daemon sets

--

- More precisely: it doesn't have a subcommand to create a daemon set

--

- But any kind of resource can always be created by providing a YAML description:
  ```bash
  kubectl apply -f foo.yaml
  ```

--

- How do we create the YAML file for our daemon set?

--

  - option 1: [read the docs](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#create-a-daemonset)

--

  - option 2: `vi` our way out of it

---

## Creating the YAML file for our daemon set

- Let's start with the YAML file for the current `rng` resource

.lab[

- Dump the `rng` resource in YAML:
  ```bash
  kubectl get deploy/rng -o yaml >rng.yml
  ```

- Edit `rng.yml`

]

---

## "Casting" a resource to another

- What if we just changed the `kind` field?

  (It can't be that easy, right?)

.lab[

- Change `kind: Deployment` to `kind: DaemonSet`

<!--
```bash vim rng.yml```
```wait kind: Deployment```
```keys /Deployment```
```key ^J```
```keys cwDaemonSet```
```key ^[``` ]
```keys :wq```
```key ^J```
-->

- Save, quit

- Try to create our new resource:
  ```bash
  kubectl apply -f rng.yml
  ```

<!-- ```wait error:``` -->

]

--

We all knew this couldn't be that easy, right!

---

## Understanding the problem

- The core of the error is:
  ```
  error validating data:
  [ValidationError(DaemonSet.spec):
  unknown field "replicas" in io.k8s.api.extensions.v1beta1.DaemonSetSpec,
  ...
  ```

--

- *Obviously,* it doesn't make sense to specify a number of replicas for a daemon set

--

- Workaround: fix the YAML

  - remove the `replicas` field
  - remove the `strategy` field (which defines the rollout mechanism for a deployment)
  - remove the `progressDeadlineSeconds` field (also used by the rollout mechanism)
  - remove the `status: {}` line at the end

--

- Or, we could also ...

---

## Use the `--force`, Luke

- We could also tell Kubernetes to ignore these errors and try anyway

- The `--force` flag's actual name is `--validate=false`

.lab[

- Try to load our YAML file and ignore errors:
  ```bash
  kubectl apply -f rng.yml --validate=false
  ```

]

--

🎩✨🐇

--

Wait ... Now, can it be *that* easy?

---

## Checking what we've done

- Did we transform our `deployment` into a `daemonset`?

.lab[

- Look at the resources that we have now:
  ```bash
  kubectl get all
  ```

]

--

We have two resources called `rng`:

- the *deployment* that was existing before

- the *daemon set* that we just created

We also have one too many pods.
<br/>
(The pod corresponding to the *deployment* still exists.)

---

## `deploy/rng` and `ds/rng`

- You can have different resource types with the same name

  (i.e. a *deployment* and a *daemon set* both named `rng`)

- We still have the old `rng` *deployment*

  ```
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/rng        1         1         1            1           18m
  ```

- But now we have the new `rng` *daemon set* as well

  ```
NAME                DESIRED  CURRENT  READY  UP-TO-DATE  AVAILABLE  NODE SELECTOR  AGE
daemonset.apps/rng  2        2        2      2           2          <none>         9s
  ```

---

## Too many pods

- If we check with `kubectl get pods`, we see:

  - *one pod* for the deployment (named `rng-xxxxxxxxxx-yyyyy`)

  - *one pod per node* for the daemon set (named `rng-zzzzz`)

  ```
  NAME                        READY     STATUS    RESTARTS   AGE
  rng-54f57d4d49-7pt82        1/1       Running   0          11m
  rng-b85tm                   1/1       Running   0          25s
  rng-hfbrr                   1/1       Running   0          25s
  [...]
  ```

--

The daemon set created one pod per node, except on the master node.

The master node has [taints](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) preventing pods from running there.

(To schedule a pod on this node anyway, the pod will require appropriate [tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/).)

.footnote[(Off by one? We don't run these pods on the node hosting the control plane.)]

---

## Is this working?

- Look at the web UI

--

- The graph should now go above 10 hashes per second!

--

- It looks like the newly created pods are serving traffic correctly

- How and why did this happen?

  (We didn't do anything special to add them to the `rng` service load balancer!)

---

# Labels and selectors

- The `rng` *service* is load balancing requests to a set of pods

- That set of pods is defined by the *selector* of the `rng` service

.lab[

- Check the *selector* in the `rng` service definition:
  ```bash
  kubectl describe service rng
  ```

]

- The selector is `app=rng`

- It means "all the pods having the label `app=rng`"

  (They can have additional labels as well, that's OK!)

---

## Selector evaluation

- We can use selectors with many `kubectl` commands

- For instance, with `kubectl get`, `kubectl logs`, `kubectl delete` ... and more

.lab[

- Get the list of pods matching selector `app=rng`:
  ```bash
  kubectl get pods -l app=rng
  kubectl get pods --selector app=rng
  ```

]

But ... why do these pods (in particular, the *new* ones) have this `app=rng` label?

---

## Where do labels come from?

- When we create a deployment with `kubectl create deployment rng`,
  <br/>this deployment gets the label `app=rng`

- The replica sets created by this deployment also get the label `app=rng`

- The pods created by these replica sets also get the label `app=rng`

- When we created the daemon set from the deployment, we re-used the same spec

- Therefore, the pods created by the daemon set get the same labels

.footnote[Note: when we use `kubectl run stuff`, the label is `run=stuff` instead.]

---

## Updating load balancer configuration

- We would like to remove a pod from the load balancer

- What would happen if we removed that pod, with `kubectl delete pod ...`?

--

  It would be re-created immediately (by the replica set or the daemon set)

--

- What would happen if we removed the `app=rng` label from that pod?

--

  It would *also* be re-created immediately

--

  Why?!?

---

## Selectors for replica sets and daemon sets

- The "mission" of a replica set is:

  "Make sure that there is the right number of pods matching this spec!"

- The "mission" of a daemon set is:

  "Make sure that there is a pod matching this spec on each node!"

--

- *In fact,* replica sets and daemon sets do not check pod specifications

- They merely have a *selector*, and they look for pods matching that selector

- Yes, we can fool them by manually creating pods with the "right" labels

- Bottom line: if we remove our `app=rng` label ...

 ... The pod "disappears" for its parent, which re-creates another pod to replace it

---

class: extra-details

## Isolation of replica sets and daemon sets

- Since both the `rng` daemon set and the `rng` replica set use `app=rng` ...

  ... Why don't they "find" each other's pods?

--

- *Replica sets* have a more specific selector, visible with `kubectl describe`

  (It looks like `app=rng,pod-template-hash=abcd1234`)

- *Daemon sets* also have a more specific selector, but it's invisible

  (It looks like `app=rng,controller-revision-hash=abcd1234`)

- As a result, each controller only "sees" the pods it manages

---

## Removing a pod from the load balancer

- Currently, the `rng` service is defined by the `app=rng` selector

- The only way to remove a pod is to remove or change the `app` label

- ... But that will cause another pod to be created instead!

- What's the solution?

--

- We need to change the selector of the `rng` service!

- Let's add another label to that selector (e.g. `active=yes`) 

---

## Selectors with multiple labels

- If a selector specifies multiple labels, they are understood as a logical *AND*

  (in other words: the pods must match all the labels)

- We cannot have a logical *OR*

  (e.g. `app=api AND (release=prod OR release=preprod)`)

- We can, however, apply as many extra labels as we want to our pods:

  - use selector `app=api AND prod-or-preprod=yes`

  - add `prod-or-preprod=yes` to both sets of pods

- We will see later that in other places, we can use more advanced selectors

---

## The plan

1. Add the label `active=yes` to all our `rng` pods

2. Update the selector for the `rng` service to also include `active=yes`

3. Toggle traffic to a pod by manually adding/removing the `active` label

4. Profit!

*Note: if we swap steps 1 and 2, it will cause a short
service disruption, because there will be a period of time
during which the service selector won't match any pod.
During that time, requests to the service will time out.
By doing things in the order above, we guarantee that there won't
be any interruption.*

---

## Adding labels to pods

- We want to add the label `active=yes` to all pods that have `app=rng`

- We could edit each pod one by one with `kubectl edit` ...

- ... Or we could use `kubectl label` to label them all

- `kubectl label` can use selectors itself

.lab[

- Add `active=yes` to all pods that have `app=rng`:
  ```bash
  kubectl label pods -l app=rng active=yes
  ```

]

---

## Updating the service selector

- We need to edit the service specification

- Reminder: in the service definition, we will see `app: rng` in two places

  - the label of the service itself (we don't need to touch that one)

  - the selector of the service (that's the one we want to change)

.lab[

- Update the service to add `active: yes` to its selector:
  ```bash
  kubectl edit service rng
  ```

<!--
```wait Please edit the object below```
```keys /app: rng```
```key ^J```
```keys noactive: yes```
```key ^[``` ]
```keys :wq```
```key ^J```
-->

]

--

... And then we get *the weirdest error ever.* Why?

---

## When the YAML parser is being too smart

- YAML parsers try to help us:

  - `xyz` is the string `"xyz"`

  - `42` is the integer `42`

  - `yes` is the boolean value `true`

- If we want the string `"42"` or the string `"yes"`, we have to quote them

- So we have to use `active: "yes"`

.footnote[For a good laugh: if we had used "ja", "oui", "si" ... as the value, it would have worked!]

---

## Updating the service selector, take 2

.lab[

- Update the YAML manifest of the service

- Add `active: "yes"` to its selector

<!--
```wait Please edit the object below```
```keys /yes```
```key ^J```
```keys cw"yes"```
```key ^[``` ]
```keys :wq```
```key ^J```
-->

]

This time it should work!

If we did everything correctly, the web UI shouldn't show any change.

---

## Updating labels

- We want to disable the pod that was created by the deployment

- All we have to do, is remove the `active` label from that pod

- To identify that pod, we can use its name

- ... Or rely on the fact that it's the only one with a `pod-template-hash` label

- Good to know:

  - `kubectl label ... foo=` doesn't remove a label (it sets it to an empty string)

  - to remove label `foo`, use `kubectl label ... foo-`

  - to change an existing label, we would need to add `--overwrite`

---

## Removing a pod from the load balancer

.lab[

- In one window, check the logs of that pod:
  ```bash
  POD=$(kubectl get pod -l app=rng,pod-template-hash -o name)
  kubectl logs --tail 1 --follow $POD
  ```
  (We should see a steady stream of HTTP logs)

<!--
```wait HTTP/1.1```
```tmux split-pane -v```
-->

- In another window, remove the label from the pod:
  ```bash
  kubectl label pod -l app=rng,pod-template-hash active-
  ```
  (The stream of HTTP logs should stop immediately)

<!--
```key ^D```
```key ^C```
-->

]

There might be a slight change in the web UI (since we removed a bit
of capacity from the `rng` service). If we remove more pods,
the effect should be more visible.

---

class: extra-details

## Updating the daemon set

- If we scale up our cluster by adding new nodes, the daemon set will create more pods

- These pods won't have the `active=yes` label

- If we want these pods to have that label, we need to edit the daemon set spec

- We can do that with e.g. `kubectl edit daemonset rng`

---

class: extra-details

## We've put resources in your resources

- Reminder: a daemon set is a resource that creates more resources!

- There is a difference between:

  - the label(s) of a resource (in the `metadata` block in the beginning)

  - the selector of a resource (in the `spec` block)

  - the label(s) of the resource(s) created by the first resource (in the `template` block)

- We would need to update the selector and the template

  (metadata labels are not mandatory)

- The template must match the selector

  (i.e. the resource will refuse to create resources that it will not select)

---

## Labels and debugging

- When a pod is misbehaving, we can delete it: another one will be recreated

- But we can also change its labels

- It will be removed from the load balancer (it won't receive traffic anymore)

- Another pod will be recreated immediately

- But the problematic pod is still here, and we can inspect and debug it

- We can even re-add it to the rotation if necessary

  (Very useful to troubleshoot intermittent and elusive bugs)

---

## Labels and advanced rollout control

- Conversely, we can add pods matching a service's selector

- These pods will then receive requests and serve traffic

- Examples:

  - one-shot pod with all debug flags enabled, to collect logs

  - pods created automatically, but added to rotation in a second step
    <br/>
    (by setting their label accordingly)

- This gives us building blocks for canary and blue/green deployments

---

class: extra-details

## Advanced label selectors

- As indicated earlier, service selectors are limited to a `AND`

- But in many other places in the Kubernetes API, we can use complex selectors

  (e.g. Deployment, ReplicaSet, DaemonSet, NetworkPolicy ...)

- These allow extra operations; specifically:

  - checking for presence (or absence) of a label

  - checking if a label is (or is not) in a given set

- Relevant documentation:

  [Service spec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#servicespec-v1-core),
  [LabelSelector spec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#labelselector-v1-meta),
  [label selector doc](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)

---

class: extra-details

## Example of advanced selector

```yaml
  theSelector:
    matchLabels:
      app: portal
      component: api
    matchExpressions:
    - key: release
      operator: In
      values: [ production, preproduction ]
    - key: signed-off-by
      operator: Exists
```

This selector matches pods that meet *all* the indicated conditions.

`operator` can be `In`, `NotIn`, `Exists`, `DoesNotExist`.

A `nil` selector matches *nothing*, a `{}` selector matches *everything*.
<br/>
(Because that means "match all pods that meet at least zero condition".)

---

class: extra-details

## Services and Endpoints

- Each Service has a corresponding Endpoints resource

  (see `kubectl get endpoints` or `kubectl get ep`)

- That Endpoints resource is used by various controllers

  (e.g. `kube-proxy` when setting up `iptables` rules for ClusterIP services)

- These Endpoints are populated (and updated) with the Service selector

- We can update the Endpoints manually, but our changes will get overwritten

- ... Except if the Service selector is empty!

---

class: extra-details

## Empty Service selector

- If a service selector is empty, Endpoints don't get updated automatically

  (but we can still set them manually)

- This lets us create Services pointing to arbitrary destinations

  (potentially outside the cluster; or things that are not in pods)

- Another use-case: the `kubernetes` service in the `default` namespace

  (its Endpoints are maintained automatically by the API server)

???

:EN:- Scaling with Daemon Sets
:FR:- Utilisation de Daemon Sets
