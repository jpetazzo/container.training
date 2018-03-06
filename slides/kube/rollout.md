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

- We have the possibility to rollback to the previous version
  <br/>(if the update fails or is unsatisfactory in any way)

---

## Rolling updates in practice

- As of Kubernetes 1.8, we can do rolling updates with:

  `deployments`, `daemonsets`, `statefulsets`

- Editing one of these resources will automatically result in a rolling update

- Rolling updates can be monitored with the `kubectl rollout` subcommand

---

## Building a new version of the `worker` service

.exercise[

- Go to the `stack` directory:
  ```bash
  cd ~/container.training/stacks
  ```

- Edit `dockercoins/worker/worker.py`, update the `sleep` line to sleep 1 second

- Build a new tag and push it to the registry:
  ```bash
  #export REGISTRY=localhost:3xxxx
  export TAG=v0.2
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  ```

]

---

## Rolling out the new `worker` service

.exercise[

- Let's monitor what's going on by opening a few terminals, and run:
  ```bash
  kubectl get pods -w
  kubectl get replicasets -w
  kubectl get deployments -w
  ```

<!-- ```keys ^C``` -->

- Update `worker` either with `kubectl edit`, or by running:
  ```bash
  kubectl set image deploy worker worker=$REGISTRY/worker:$TAG
  ```

]

--

That rollout should be pretty quick. What shows in the web UI?

---

## Rolling out a boo-boo

- What happens if we make a mistake?

.exercise[

- Update `worker` by specifying a non-existent image:
  ```bash
  export TAG=v0.3
  kubectl set image deploy worker worker=$REGISTRY/worker:$TAG
  ```

- Check what's going on:
  ```bash
  kubectl rollout status deploy worker
  ```

]

--

Our rollout is stuck. However, the app is not dead (just 10% slower).

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

- Cancel the deployment and wait for the dust to settle down:
  ```bash
  kubectl rollout undo deploy worker
  kubectl rollout status deploy worker
  ```

]

---

## Changing rollout parameters

- We want to:

  - revert to `v0.1`
  - be conservative on availability (always have desired number of available workers)
  - be aggressive on rollout speed (update more than one pod at a time) 
  - give some time to our workers to "warm up" before starting more

The corresponding changes can be expressed in the following YAML snippet:

.small[
```yaml
spec:
  template:
    spec:
      containers:
      - name: worker
        image: $REGISTRY/worker:v0.1
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  minReadySeconds: 10
```
]

---

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
            image: $REGISTRY/worker:v0.1
      strategy:
        rollingUpdate:
          maxUnavailable: 0
          maxSurge: 3
      minReadySeconds: 10
    "
  kubectl rollout status deployment worker
  ```
  ] 

]
