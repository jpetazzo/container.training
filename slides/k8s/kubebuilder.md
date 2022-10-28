# Kubebuilder

- Writing a quick and dirty operator is (relatively) easy

- Doing it right, however ...

--

- We need:

  - proper CRD with schema validation

  - controller performing a reconcilation loop

  - manage errors, retries, dependencies between resources

  - maybe webhooks for admission and/or conversion

😱

---

## Frameworks

- There are a few frameworks available out there:

  - [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
    ([book](https://book.kubebuilder.io/)):
    go-centric, very close to Kubernetes' core types

  - [operator-framework](https://operatorframework.io/):
    higher level; also supports Ansible and Helm

  - [KUDO](https://kudo.dev/):
    declarative operators written in YAML

  - [KOPF](https://kopf.readthedocs.io/en/latest/):
    operators in Python

  - ...

---

## Kubebuilder workflow

- Kubebuilder will create scaffolding for us

  (Go stubs for types and controllers)

- Then we edit these types and controllers files

- Kubebuilder generates CRD manifests from our type definitions

  (and regenerates the manifests whenver we update the types)

- It also gives us tools to quickly run the controller against a cluster

  (not necessarily *on* the cluster)

---

## Our objective

- We're going to implement a *useless machine*

  [basic example](https://www.youtube.com/watch?v=aqAUmgE3WyM)
  |
  [playful example](https://www.youtube.com/watch?v=kproPsch7i0)
  |
  [advanced example](https://www.youtube.com/watch?v=Nqk_nWAjBus)
  |
  [another advanced example](https://www.youtube.com/watch?v=eLtUB8ncEnA)

- A machine manifest will look like this:
  ```yaml
    kind: Machine
    apiVersion: useless.container.training/v1alpha1
    metadata:
      name: machine-1
    spec:
      # Our useless operator will change that to "down"
      switchPosition: up
  ```

- Each time we change the `switchPosition`, the operator will move it back to `down`

(This is inspired by the
[uselessoperator](https://github.com/tilt-dev/uselessoperator)
written by
[V Körbes](https://twitter.com/veekorbes).
Highly recommend!💯)

---

class: extra-details

## Local vs remote

- Building Go code can be a little bit slow on our modest lab VMs

- It will typically be *much* faster on a local machine

- All the demos and labs in this section will run fine either way!

---


## Preparation

- Install Go

  (on our VMs: `sudo snap install go --classic`)

- Install kubebuilder

  ([get a release](https://github.com/kubernetes-sigs/kubebuilder/releases/), untar, move the `kubebuilder` binary to the `$PATH`)

- Initialize our workspace:
  ```bash
  mkdir useless
  cd useless
  go mod init container.training/useless
  kubebuilder init --domain container.training
  ```

---

## Create scaffolding

- Create a type and corresponding controller:
  ```bash
  kubebuilder create api --group useless --version v1alpha1 --kind Machine
  ```

- Answer `y` to both questions

- Then we need to edit the type that just got created!

---

## Edit type

Edit `api/v1alpha1/machine_types.go`.

Add the `switchPosition` field in the `spec` structure:

```go
// MachineSpec defines the desired state of Machine
type MachineSpec struct {
	// Position of the switch on the machine, for instance up or down.
	SwitchPosition string ``json:"switchPosition,omitempty"``
}
```

⚠️ The backticks above should be simple backticks, not double-backticks. Sorry.

---

## Go markers

We can use Go *marker comments* to give `controller-gen` extra details about how to handle our type, for instance:

```go
//+kubebuilder:object:root=true
```

→ top-level type exposed through API (as opposed to "member field of another type")

```go
//+kubebuilder:subresource:status
```

→ automatically generate a `status` subresource (very common with many types)

```go
//+kubebuilder:printcolumn:JSONPath=".spec.switchPosition",name=Position,type=string
```

(See
[marker syntax](https://book.kubebuilder.io/reference/markers.html),
[CRD generation](https://book.kubebuilder.io/reference/markers/crd.html),
[CRD validation](https://book.kubebuilder.io/reference/markers/crd-validation.html),
[Object/DeepCopy](https://master.book.kubebuilder.io/reference/markers/object.html)
)

---

## Installing the CRD

After making these changes, we can run `make install`.

This will build the Go code, but also:

- generate the CRD manifest

- and apply the manifest to the cluster

---

## Creating a machine

Edit `config/samples/useless_v1alpha1_machine.yaml`:

```yaml
kind: Machine
apiVersion: useless.container.training/v1alpha1
metadata:
  labels: # ...
  name: machine-1
spec:
  # Our useless operator will change that to "down"
  switchPosition: up
```

... and apply it to the cluster.

---

## Designing the controller

- Our controller needs to:

  - notice when a `switchPosition` is not `down`

  - move it to `down` when that happens

- Later, we can add fancy improvements (wait a bit before moving it, etc.)

---

## Reconciler logic

- Kubebuilder will call our *reconciler* when necessary

- When necessary = when changes happen ...

  - on our resource

  - or resources that it *watches* (related resources)

- After "doing stuff", the reconciler can return ...

  - `ctrl.Result{},nil` = all is good

  - `ctrl.Result{Requeue...},nil` = all is good, but call us back in a bit

  - `ctrl.Result{},err` = something's wrong, try again later

---

## Loading an object

Open `controllers/machine_controller.go`.

Add that code in the `Reconcile` method, at the `TODO(user)` location:

```go
var machine uselessv1alpha1.Machine
logger := log.FromContext(ctx)

if err := r.Get(ctx, req.NamespacedName, &machine); err != nil {
  logger.Info("error getting object")
  return ctrl.Result{}, err
}

logger.Info(
  "reconciling",
  "machine", req.NamespacedName,
  "switchPosition", machine.Spec.SwitchPosition,
)
```

---

## Running the controller

Our controller is not done yet, but let's try what we have right now!

This will compile the controller and run it:
```
make run
```

Then:

- create a machine
- change the `switchPosition`
- delete the machine

--

We get a bunch of errors and go stack traces! 🤔

---

## `IgnoreNotFound`

When we are called for object deletion, the object has *already* been deleted.

(Unless we're using finalizers, but that's another story.)

When we return `err`, the controller will try to access the object ...

... We need to tell it to *not* do that.

Don't just return `err`, but instead, wrap it around `client.IgnoreNotFound`:

```go
return ctrl.Result{}, client.IgnoreNotFound(err)
```

Update the code, `make run` again, create/change/delete again.

--

🎉

---

## Updating the machine

Let's try to update the machine like this:

```go
if machine.Spec.SwitchPosition != "down" {
	machine.Spec.SwitchPosition = "down"
	if err := r.Update(ctx, &machine); err != nil {
		logger.Info("error updating switch position")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
}
```

Again - update, `make run`, test.

---

## Spec vs Status

- Spec = desired state

- Status = observed state

- If Status is lost, the controller should be able to reconstruct it

  (maybe with degraded behavior in the meantime)

- Status will almost always be a sub-resource, so that it can be updated separately

  (and potentially with different permissions)

---

class: extra-details

## Spec vs Status (in depth)

- The `/status` subresource is handled differently by the API server

- Updates to `/status` don't alter the rest of the object

- Conversely, updates to the object ignore changes in the status

(See [the docs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#status-subresource) for the fine print.)

---

## "Improving" our controller

- We want to wait a few seconds before flipping the switch

- Let's add the following line of code to the controller:
  ```go
  time.Sleep(5 * time.Second)
  ```

- `make run`, create a few machines, observe what happens

--

💡 Concurrency!

---

## Controller logic

- Our controller shouldn't block (think "event loop")

- There is a queue of objects that need to be reconciled

- We can ask to be put back on the queue for later processing

- When we need to block (wait for something to happen), two options:

  - ask for a *requeue* ("call me back later")

  - yield because we know we will be notified by another resource

---

## To requeue ...

`return ctrl.Result{RequeueAfter: 1 * time.Second}, nil`

- That means: "try again in 1 second, and I will check if progress was made"

- This *does not* guarantee that we will be called exactly 1 second later:

  - we might be called before (if other changes happen)

  - we might be called after (if the controller is busy with other objects)

- If we are waiting for another Kubernetes resource to change, there is a better way

  (explained on next slide)

---

## ... or not to requeue

`return ctrl.Result{}, nil`

- That means: "we're done here!"

- This is also what we should use if we are waiting for another resource

  (e.g. a LoadBalancer to be provisioned, a Pod to be ready...)

- In that case, we will need to set a *watch* (more on that later)

---

## Keeping track of state

- If we simply requeue the object to examine it 1 second later...

- ...We'll keep examining/requeuing it forever!

- We need to "remember" that we saw it (and when)

- Option 1: keep state in controller

  (e.g. an internal `map`)

- Option 2: keep state in the object

  (typically in its status field)

- Tradeoffs: concurrency / failover / control plane overhead...

---

## "Improving" our controller, take 2

Let's store in the machine status the moment when we saw it:

```go
type MachineStatus struct {
	// Time at which the machine was noticed by our controller.
	SeenAt *metav1.Time ``json:"seenAt,omitempty"``
}
```

⚠️ The backticks above should be simple backticks, not double-backticks. Sorry.

Note: `date` fields don't display timestamps in the future.

(That's why for this example it's simpler to use `seenAt` rather than `changeAt`.)

And for better visibility, add this along with the other `printcolumn` comments:

```go
//+kubebuilder:printcolumn:JSONPath=".status.seenAt",name=Seen,type=date
```

---

## Set `seenAt`

Let's add the following block in our reconciler:

```go
if machine.Status.SeenAt == nil {
	now := metav1.Now()
	machine.Status.SeenAt = &now
	if err := r.Status().Update(ctx, &machine); err != nil {
		logger.Info("error updating status.seenAt")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
	return ctrl.Result{RequeueAfter: 5 * time.Second}, nil
}
```

(If needed, add `metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"` to our imports.)

---

## Use `seenAt`

Our switch-position-changing code can now become:

```go
if machine.Spec.SwitchPosition != "down" {
	now := metav1.Now()
	changeAt := machine.Status.SeenAt.Time.Add(5 * time.Second)
	if now.Time.After(changeAt) {
		machine.Spec.SwitchPosition = "down"
    machine.Status.SeenAt = nil
		if err := r.Update(ctx, &machine); err != nil {
			logger.Info("error updating switch position")
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
	}
}
```

`make run`, create a few machines, tweak their switches.

---

## Owner and dependents

- Next, let's see how to have relationships between objects!

- We will now have two kinds of objects: machines, and switches

- Machines will store the number of switches in their spec

- Machines should have *at least* one switch, possibly *multiple ones*

- Our controller will automatically create switches if needed

  (a bit like the ReplicaSet controller automatically creates Pods)

- The switches will be tied to their machine through a label

  (let's pick `machine=name-of-the-machine`)

---

## Switch state

- The position of a switch will now be stored in the switch

  (not in the machine like in the first scenario)

- The machine will also expose the combined state of the switches

  (through its status)

- The machine's status will be automatically updated by the controller

  (each time a switch is added/changed/removed)

---

## Switches and machines

```
[jp@hex ~]$ kubectl get machines
NAME            SWITCHES   POSITIONS
machine-cz2vl   3          ddd
machine-vf4xk   1          d

[jp@hex ~]$ kubectl get switches --show-labels
NAME           POSITION   SEEN   LABELS
switch-6wmjw   down              machine=machine-cz2vl
switch-b8csg   down              machine=machine-cz2vl
switch-fl8dq   down              machine=machine-cz2vl
switch-rc59l   down              machine=machine-vf4xk
```

(The field `status.positions` shows the first letter of the `position` of each switch.)

---

## Tasks

1. Create the new resource type (but don't create a controller)

2. Update `machine_types.go` and `switch_types.go`

3. Implement logic to display machine status (status of its switches)

4. Implement logic to automatically create switches

5. Implement logic to flip all switches down immediately

6. Then tweak it so that a given machine doesn't flip more than one switch every 5 seconds

*See next slides for detailed steps!*

---

## Creating the new type

```bash
kubebuilder create api --group useless --version v1alpha1 --kind Switch
```

Note: this time, only create a new custom resource; not a new controller.

---

## Updating our types

- Move the "switch position" and "seen at" to the new `Switch` type

- Update the `Machine` type to have:

  - `spec.switches` (Go type: `int`, JSON type: `integer`)

  - `status.positions` of type `string`

- Bonus points for adding [CRD Validation](https://book.kubebuilder.io/reference/markers/crd-validation.html) to the numbers of switches!

- Then install the new CRDs with `make install`

- Create a Machine, and a Switch linked to the Machine (by setting the `machine` label)

---

## Listing switches

- Switches are associated to Machines with a label

  (`kubectl label switch switch-xyz machine=machine-xyz`)

- We can retrieve associated switches like this:

  ```go
  var switches uselessv1alpha1.SwitchList

  if err := r.List(ctx, &switches,
    client.InNamespace(req.Namespace),
    client.MatchingLabels{"machine": req.Name},
    ); err != nil {
    logger.Error(err, "unable to list switches of the machine")
    return ctrl.Result{}, client.IgnoreNotFound(err)
  }

  logger.Info("Found switches", "switches", switches)
  ```

---

## Updating status

- Each time we reconcile a Machine, let's update its status:

  ```go
  status := ""
  for _, sw := range switches.Items {
    status += string(sw.Spec.Position[0])
  }
  machine.Status.Positions = status
  if err := r.Status().Update(ctx, &machine); err != nil {
    ...
  ```

- Run the controller and check that POSITIONS gets updated

- Add more switches linked to the same machine

- ...The POSITIONS don't get updated, unless we restart the controller

- We'll see later how to fix that!

---

## Creating objects

We can use the `Create` method to create a new object:

```go
sw := uselessv1alpha1.Switch{
	TypeMeta: metav1.TypeMeta{
		APIVersion: uselessv1alpha1.GroupVersion.String(),
		Kind:       "Switch",
	},
	ObjectMeta: metav1.ObjectMeta{
		GenerateName: "switch-",
		Namespace:    machine.Namespace,
		Labels:       map[string]string{"machine": machine.Name},
	},
	Spec: uselessv1alpha1.SwitchSpec{
		Position: "down",
	},
}
if err := r.Create(ctx, &sw); err != nil { ...
```

---

## Create missing switches

- In our reconciler, if a machine doesn't have enough switches, create them!

- Option 1: directly create the number of missing switches

- Option 2: create only one switch (and rely on later requeuing)

- Note: option 2 won't quite work yet, since we haven't set up *watches* yet

---

## Watches

- Our controller doesn't react when switches are created/updated/deleted

- We need to tell it to watch switches

- We also need to tell it how to map a switch to its machine

  (so that the correct machine gets queued and reconciled when a switch is updated)

---

## Mapping a switch to its machine

Define the following helper function:

```go
func (r *MachineReconciler) machineOfSwitch(obj client.Object) []ctrl.Request {
  return []ctrl.Request{
    ctrl.Request{
      NamespacedName: types.NamespacedName{
        Name:      obj.GetLabels()["machine"],
        Namespace: obj.GetNamespace(),
      },
    },
  }
}
```

---

## Telling the controller to watch switches

Update the `SetupWithManager` method in the controller:

```go
// SetupWithManager sets up the controller with the Manager.
func (r *MachineReconciler) SetupWithManager(mgr ctrl.Manager) error {
  return ctrl.NewControllerManagedBy(mgr).
    For(&uselessv1alpha1.Machine{}).
    Owns(&uselessv1alpha1.Switch{}).
    Watches(
      &source.Kind{Type: &uselessv1alpha1.Switch{}},
      handler.EnqueueRequestsFromMapFunc(r.machineOfSwitch),
    ).
    Complete(r)
}
```

---

## ...And a few extra imports

Import the following packages referenced by the previous code:

```go
"sigs.k8s.io/controller-runtime/pkg/handler"
"sigs.k8s.io/controller-runtime/pkg/source"
"k8s.io/apimachinery/pkg/types"
```

After this, when we update a switch, it should reflect on the machine.

(Try to change switch positions and see the machine status update!)

---

## Flipping switches

- Now re-add logic to flip switches that are not in "down" position

- Re-add logic to wait a few seconds before flipping a switch

- Change the logic to toggle one switch per machine every few seconds

  (i.e. don't change all the switches for a machine; move them one at a time)

- Handle "scale down" of a machine (by deleting extraneous switches)

- Automatically delete switches when a machine is deleted

  (ideally, using ownership information)

- Test corner cases (e.g. changing a switch label)

---

## Other possible improvements

- Formalize resource ownership

  (by setting `ownerReferences` in the switches)

- This can simplify the watch mechanism a bit

- Allow to define a selector

  (instead of using the hard-coded `machine` label)

- And much more!

---

## Acknowledgements

- Useless Operator, by [V Körbes](https://twitter.com/veekorbes)

  [code](https://github.com/tilt-dev/uselessoperator)
  |
  [video (EN)](https://www.youtube.com/watch?v=85dKpsFFju4)
  |
  [video (PT)](https://www.youtube.com/watch?v=Vt7Eg4wWNDw)

- Zero To Operator, by [Solly Ross](https://twitter.com/directxman12)

  [code](https://pres.metamagical.dev/kubecon-us-2019/code)
  |
  [video](https://www.youtube.com/watch?v=KBTXBUVNF2I)
  |
  [slides](https://pres.metamagical.dev/kubecon-us-2019/)

- The [kubebuilder book](https://book.kubebuilder.io/)

???

:EN:- Implementing an operator with kubebuilder
:FR:- Implémenter un opérateur avec kubebuilder
