# Recording deployment actions

- Some commands that modify a Deployment accept an optional `--record` flag

  (Example: `kubectl set image deployment worker worker=alpine --record`)

- That flag will store the command line in the Deployment

  (Technically, using the annotation `kubernetes.io/change-cause`)

- It gets copied to the corresponding ReplicaSet

  (Allowing to keep track of which command created or promoted this ReplicaSet)

- We can view this information with `kubectl rollout history`

---

## Using `--record`

- Let's make a couple of changes to a Deployment and record them

.lab[

- Roll back `worker` to image version 0.1:
  ```bash
  kubectl set image deployment worker worker=dockercoins/worker:v0.1 --record
  ```

- Promote it to version 0.2 again:
  ```bash
  kubectl set image deployment worker worker=dockercoins/worker:v0.2 --record
  ```

- View the change history:
  ```bash
  kubectl rollout history deployment worker
  ```

]

---

## Pitfall #1: forgetting `--record`

- What happens if we don't specify `--record`?

.lab[

- Promote `worker` to image version 0.3:
  ```bash
  kubectl set image deployment worker worker=dockercoins/worker:v0.3
  ```

- View the change history:
  ```bash
  kubectl rollout history deployment worker
  ```

]

--

It recorded version 0.2 instead of 0.3! Why?

---

## How `--record` really works

- `kubectl` adds the annotation `kubernetes.io/change-cause` to the Deployment

- The Deployment controller copies that annotation to the ReplicaSet

- `kubectl rollout history` shows the ReplicaSets' annotations

- If we don't specify `--record`, the annotation is not updated

- The previous value of that annotation is copied to the new ReplicaSet

- In that case, the ReplicaSet annotation does not reflect reality!

---

## Pitfall #2: recording `scale` commands

- What happens if we use `kubectl scale --record`?

.lab[

- Check the current history:
  ```bash
  kubectl rollout history deployment worker
  ```

- Scale the deployment:
  ```bash
  kubectl scale deployment worker --replicas=3 --record
  ```

- Check the change history again:
  ```bash
  kubectl rollout history deployment worker
  ```

]

--

The last entry in the history was overwritten by the `scale` command! Why?

---

## Actions that don't create a new ReplicaSet

- The `scale` command updates the Deployment definition

- But it doesn't create a new ReplicaSet

- Using the `--record` flag sets the annotation like before

- The annotation gets copied to the existing ReplicaSet

- This overwrites the previous annotation that was there

- In that case, we lose the previous change cause!

---

## Updating the annotation directly

- Let's see what happens if we set the annotation manually

.lab[

- Annotate the Deployment:
  ```bash
  kubectl annotate deployment worker kubernetes.io/change-cause="Just for fun"
  ```

- Check that our annotation shows up in the change history:
  ```bash
  kubectl rollout history deployment worker
  ```

]

--

Our annotation shows up (and overwrote whatever was there before).

---

## Using change cause

- It sounds like a good idea to use `--record`, but:

  *"Incorrect documentation is often worse than no documentation."*
  <br/>
  (Bertrand Meyer)

- If we use `--record` once, we need to either:

  - use it every single time after that

  - or clear the Deployment annotation after using `--record`
    <br/>
    (subsequent changes will show up with a `<none>` change cause)

- A safer way is to set it through our tooling
