# Running our application on Kubernetes

- We can now deploy our code (as well as a redis instance)

.exercise[

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

.exercise[

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

.exercise[

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

.exercise[

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

- We will expose it with a `LoadBalancer`

.exercise[

- Create a `NodePort` service for the Web UI:
  ```bash
  kubectl expose deploy/webui --type=LoadBalancer --port=80
  ```

- Check the results that was allocated:
  ```bash
  kubectl get svc
  ```
]
--

Wait a few moments and rerun `kubectl get svc` you should see the `EXTERNAL-IP` go from *pending* to an IP address.

---

## Accessing the web UI

- We can now connect to the `EXTERNAL-IP` of the allocated load balancer

.exercise[

- Get the `EXTERNAL-IP`:
  ```bash
  LB=$(kubectl get svc httpenv -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  ```

- Open the web UI in your browser
  ```bash
  firefox http://$LB
  ```

]
