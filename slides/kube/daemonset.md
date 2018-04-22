# Daemon sets

- We want to scale `rng` in a way that is different from how we scaled `worker`

- We want one (and exactly one) instance of `rng` per node

- What if we just scale up `deploy/rng` to the number of nodes?

  - nothing guarantees that the `rng` containers will be distributed evenly

  - if we add nodes later, they will not automatically run a copy of `rng`

  - if we remove (or reboot) a node, one `rng` container will restart elsewhere

- Instead of a `deployment`, we will use a `daemonset`

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

- Unfortunately, as of Kubernetes 1.10, the CLI cannot create daemon sets

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

.exercise[

- Dump the `rng` resource in YAML:
  ```bash
  kubectl get deploy/rng -o yaml --export >rng.yml 
  ```

- Edit `rng.yml`

]

Note: `--export` will remove "cluster-specific" information, i.e.:
- namespace (so that the resource is not tied to a specific namespace)
- status and creation timestamp (useless when creating a new resource)
- resourceVersion and uid (these would cause... *interesting* problems)

---

## "Casting" a resource to another

- What if we just changed the `kind` field?

  (It can't be that easy, right?)

.exercise[

- Change `kind: Deployment` to `kind: DaemonSet`

- Save, quit

- Try to create our new resource:
  ```bash
  kubectl apply -f rng.yml
  ```

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
  - remove the `status: {}` line at the end

--

- Or, we could also ...

---

## Use the `--force`, Luke

- We could also tell Kubernetes to ignore these errors and try anyway

- The `--force` flag's actual name is `--validate=false`

.exercise[

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

.exercise[

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

## What are all these pods doing?

- Let's check the logs of all these `rng` pods

- All these pods have a `run=rng` label:

  - the first pod, because that's what `kubectl run` does
  - the other ones (in the daemon set), because we
    *copied the spec from the first one*

- Therefore, we can query everybody's logs using that `run=rng` selector

.exercise[

- Check the logs of all the pods having a label `run=rng`:
  ```bash
  kubectl logs -l run=rng --tail 1
  ```

]

--

It appears that *all the pods* are serving requests at the moment.

---

## The magic of selectors

- The `rng` *service* is load balancing requests to a set of pods

- This set of pods is defined as "pods having the label `run=rng`"

.exercise[

- Check the *selector* in the `rng` service definition:
  ```bash
  kubectl describe service rng
  ```

]

When we created additional pods with this label, they were
automatically detected by `svc/rng` and added as *endpoints*
to the associated load balancer.

---

## Removing the first pod from the load balancer

- What would happen if we removed that pod, with `kubectl delete pod ...`?

--

  The `replicaset` would re-create it immediately.

--

- What would happen if we removed the `run=rng` label from that pod?

--

  The `replicaset` would re-create it immediately.

--

  ... Because what matters to the `replicaset` is the number of pods *matching that selector.*

--

- But but but ... Don't we have more than one pod with `run=rng` now?

--

  The answer lies in the exact selector used by the `replicaset` ...

---

## Deep dive into selectors

- Let's look at the selectors for the `rng` *deployment* and the associated *replica set*

.exercise[

- Show detailed information about the `rng` deployment:
  ```bash
  kubectl describe deploy rng
  ```

- Show detailed information about the `rng` replica:
  <br/>(The second command doesn't require you to get the exact name of the replica set)
  ```bash
  kubectl describe rs rng-yyyy
  kubectl describe rs -l run=rng
  ```

]

--

The replica set selector also has a `pod-template-hash`, unlike the pods in our daemon set.

---

# Updating a service through labels and selectors

- What if we want to drop the `rng` deployment from the load balancer?

- Option 1: 

  - destroy it

- Option 2: 

  - add an extra *label* to the daemon set

  - update the service *selector* to refer to that *label*

--

Of course, option 2 offers more learning opportunities. Right?

---

## Add an extra label to the daemon set

- We will update the daemon set "spec"

- Option 1:

  - edit the `rng.yml` file that we used earlier

  - load the new definition with `kubectl apply`

- Option 2: 

  - use `kubectl edit`

--

*If you feel like you got this💕🌈, feel free to try directly.*

*We've included a few hints on the next slides for your convenience!*

---

## We've put resources in your resources

- Reminder: a daemon set is a resource that creates more resources!

- There is a difference between:

  - the label(s) of a resource (in the `metadata` block in the beginning)

  - the selector of a resource (in the `spec` block)

  - the label(s) of the resource(s) created by the first resource (in the `template` block)

- You need to update the selector and the template (metadata labels are not mandatory)

- The template must match the selector

  (i.e. the resource will refuse to create resources that it will not select)

---

## Adding our label

- Let's add a label `isactive: yes`

- In YAML, `yes` should be quoted; i.e. `isactive: "yes"`

.exercise[

- Update the daemon set to add `isactive: "yes"` to the selector and template label:
  ```bash
  kubectl edit daemonset rng
  ```

- Update the service to add `isactive: "yes"` to its selector:
  ```bash
  kubectl edit service rng
  ```

]

---

## Checking what we've done

.exercise[

- Check the most recent log line of all `run=rng` pods to confirm that exactly one per node is now active:
  ```bash
  kubectl logs -l run=rng --tail 1
  ```

]

The timestamps should give us a hint about how many pods are currently receiving traffic.

.exercise[

- Look at the pods that we have right now:
  ```bash
  kubectl get pods
  ```

]

---

## Cleaning up

- The pods of the deployment and the "old" daemon set are still running

- We are going to identify them programmatically

.exercise[

- List the pods with `run=rng` but without `isactive=yes`:
  ```bash
  kubectl get pods -l run=rng,isactive!=yes
  ```

- Remove these pods:
  ```bash
  kubectl delete pods -l run=rng,isactive!=yes
  ```

]

---

## Cleaning up stale pods

```
$ kubectl get pods
NAME                        READY     STATUS        RESTARTS   AGE
rng-54f57d4d49-7pt82        1/1       Terminating   0          51m
rng-54f57d4d49-vgz9h        1/1       Running       0          22s
rng-b85tm                   1/1       Terminating   0          39m
rng-hfbrr                   1/1       Terminating   0          39m
rng-vplmj                   1/1       Running       0          7m
rng-xbpvg                   1/1       Running       0          7m
[...]
```

- The extra pods (noted `Terminating` above) are going away

- ... But a new one (`rng-54f57d4d49-vgz9h` above) was restarted immediately!

--

- Remember, the *deployment* still exists, and makes sure that one pod is up and running

- If we delete the pod associated to the deployment, it is recreated automatically

---

## Deleting a deployment

.exercise[

- Remove the `rng` deployment:
  ```bash
  kubectl delete deployment rng
  ```
]

--

- The pod that was created by the deployment is now being terminated:

```
$ kubectl get pods
NAME                        READY     STATUS        RESTARTS   AGE
rng-54f57d4d49-vgz9h        1/1       Terminating   0          4m
rng-vplmj                   1/1       Running       0          11m
rng-xbpvg                   1/1       Running       0          11m
[...]
```

Ding, dong, the deployment is dead! And the daemon set lives on.

---

## Avoiding extra pods

- When we changed the definition of the daemon set, it immediately created new pods. We had to remove the old ones manually.

- How could we have avoided this?

--

- By adding the `isactive: "yes"` label to the pods before changing the daemon set!

- This can be done programmatically with `kubectl patch`:

  ```bash
    PATCH='
    metadata:
      labels:
        isactive: "yes"
    '
    kubectl get pods -l run=rng -l controller-revision-hash -o name |
      xargs kubectl patch -p "$PATCH" 
  ```

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
