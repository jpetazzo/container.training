# Running our application on Kubernetes

- We can now deploy our code (as well as a redis instance)

.lab[

- Deploy `redis`:
  ```bash
  kubectl create deployment redis --image=redis
  ```

- Deploy everything else:
  ```bash
  kubectl create deployment hasher --image=dockercoins/hasher:v0.1
  kubectl create deployment rng --image=dockercoins/rng:v0.1
  kubectl create deployment webui --image=dockercoins/webui:v0.1
  kubectl create deployment worker --image=dockercoins/worker:v0.1
  ```

]

---

class: extra-details

## Deploying other images

- If we wanted to deploy images from another registry ...

- ... Or with a different tag ...

- ... We could use the following snippet:

```bash
  REGISTRY=dockercoins
  TAG=v0.1
  for SERVICE in hasher rng webui worker; do
    kubectl create deployment $SERVICE --image=$REGISTRY/$SERVICE:$TAG
  done
```

---

## Is this working?

- After waiting for the deployment to complete, let's look at the logs!

  (Hint: use `kubectl get deploy -w` to watch deployment events)

.lab[

<!-- ```hide
kubectl wait deploy/rng --for condition=available
kubectl wait deploy/worker --for condition=available
``` -->

- Look at some logs:
  ```bash
  kubectl logs deploy/rng
  kubectl logs deploy/worker
  ```

]

--

🤔 `rng` is fine ... But not `worker`.

--

💡 Oh right! We forgot to `expose`.

---

## Connecting containers together

- Three deployments need to be reachable by others: `hasher`, `redis`, `rng`

- `worker` doesn't need to be exposed

- `webui` will be dealt with later

.lab[

- Expose each deployment, specifying the right port:
  ```bash
  kubectl expose deployment redis --port 6379
  kubectl expose deployment rng --port 80
  kubectl expose deployment hasher --port 80
  ```

]

---

## Is this working yet?

- The `worker` has an infinite loop, that retries 10 seconds after an error

.lab[

- Stream the worker's logs:
  ```bash
  kubectl logs deploy/worker --follow
  ```

  (Give it about 10 seconds to recover)

<!--
```wait units of work done, updating hash counter```
```key ^C```
-->

]

--

We should now see the `worker`, well, working happily.

---

## Exposing services for external access

- Now we would like to access the Web UI

- We will expose it with a `NodePort`

  (just like we did for the registry)

.lab[

- Create a `NodePort` service for the Web UI:
  ```bash
  kubectl expose deploy/webui --type=NodePort --port=80
  ```

- Check the port that was allocated:
  ```bash
  kubectl get svc
  ```

]

---

## Accessing the web UI

- We can now connect to *any node*, on the allocated node port, to view the web UI

.lab[

- Open the web UI in your browser (http://node-ip-address:3xxxx/)

<!-- ```open http://node1:3xxxx/``` -->

]

--

Yes, this may take a little while to update. *(Narrator: it was DNS.)*

--

*Alright, we're back to where we started, when we were running on a single node!*

???

:EN:- Running our demo app on Kubernetes
:FR:- Faire tourner l'application de démo sur Kubernetes
