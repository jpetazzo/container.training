# Scaling a deployment

- We will start with an easy one: the `worker` deployment

.exercise[

- Open two new terminals to check what's going on with pods and deployments:
  ```bash
  kubectl get pods -w
  kubectl get deployments -w
  ```

<!--
```wait RESTARTS```
```key ^C```
```wait AVAILABLE```
```key ^C```
-->

- Now, create more `worker` replicas:
  ```bash
  kubectl scale deploy/worker --replicas=10
  ```

]

After a few seconds, the graph in the web UI should show up.
<br/>
(And peak at 10 hashes/second, just like when we were running on a single one.)
