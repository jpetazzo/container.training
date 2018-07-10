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
