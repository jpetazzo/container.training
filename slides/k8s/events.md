# Events

- Kubernetes has an internal structured log of *events*

- These events are ordinary resources:

  - we can view them with `kubectl get events`

  - they can be viewed and created through the Kubernetes API

  - they are stored in Kubernetes default database (e.g. etcd)

- Most components will generate events to let us know what's going on

- Events can be *related* to other resources

---

## Reading events

- `kubectl get events` (or `kubectl get ev`)

- Can use `--watch`

  ⚠️ Looks like `tail -f`, but events aren't necessarily sorted!

- Can use `--all-namespaces`

- Cluster events (e.g. related to nodes) are in the `default` namespace

- Viewing all "non-normal" events:
  ```bash
  kubectl get ev -A --field-selector=type!=Normal
  ```

  (as of Kubernetes 1.19, `type` can be either `Normal` or `Warning`)

---

## Reading events (take 2)

- When we use `kubectl describe` on an object, `kubectl` retrieves the associated events

.lab[

- See the API requests happening when we use `kubectl describe`:
  ```bash
  kubectl describe service kubernetes --namespace=default -v6 >/dev/null
  ```

]

---

## Generating events

- This is rarely (if ever) done manually

  (i.e. by crafting some YAML)

- But controllers (e.g. operators) need this!

- It's not mandatory, but it helps with *operability*

  (e.g. when we `kubectl describe` a CRD, we will see associated events)

---

## ⚠️ Work in progress

- "Events" can be :

  - "old-style" events (in core API group, aka `v1`)

  - "new-style" events (in API group `events.k8s.io`)

- See [KEP 383](https://github.com/kubernetes/enhancements/blob/master/keps/sig-instrumentation/383-new-event-api-ga-graduation/README.md) in particular this [comparison between old and new APIs](https://github.com/kubernetes/enhancements/blob/master/keps/sig-instrumentation/383-new-event-api-ga-graduation/README.md#comparison-between-old-and-new-apis)

---

## Experimenting with events

- Let's create an event related to a Node, based on @@LINK[k8s/event-node.yaml]

.lab[

- Edit `k8s/event-node.yaml`

- Update the `name` and `uid` of the `involvedObject`

- Create the event with `kubectl create -f`

- Look at the Node with `kubectl describe`

]

---

## Experimenting with events

- Let's create an event related to a Pod, based on @@LINK[k8s/event-pod.yaml]

.lab[

- Create a pod

- Edit `k8s/event-pod.yaml`

- Edit the `involvedObject` section (don't forget the `uid`)

- Create the event with `kubectl create -f`

- Look at the Pod with `kubectl describe`

]

---

## Generating events in practice

- In Go, use an `EventRecorder` provided by the `kubernetes/client-go` library

  - [EventRecorder interface](https://github.com/kubernetes/client-go/blob/release-1.19/tools/record/event.go#L87)
  
  - [kubebuilder book example](https://book-v1.book.kubebuilder.io/beyond_basics/creating_events.html)

- It will take care of formatting / aggregating events

- To get an idea of what to put in the `reason` field, check [kubelet events](
https://github.com/kubernetes/kubernetes/blob/release-1.19/pkg/kubelet/events/event.go)

---

## Cluster operator perspective

- Events are kept 1 hour by default

- This can be changed with the `--event-ttl` flag on the API server

- On very busy clusters, events can be kept on a separate etcd cluster

- This is done with the `--etcd-servers-overrides` flag on the API server

- Example:
  ```
  --etcd-servers-overrides=/events#http://127.0.0.1:12379
  ```

???

:EN:- Consuming and generating cluster events
:FR:- Suivre l'activité du cluster avec les *events*
