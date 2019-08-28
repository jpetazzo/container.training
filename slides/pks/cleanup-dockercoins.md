# Let's do some housekeeping

- We've created a lot of resources, let's clean them up.

.exercise[
  - Delete resources:
  ```bash
  kubectl delete deployment,svc hasher redis rng webui
  kubectl delete deployment worker
  kubectl delete ingress webui
  kubectl delete daemonset rng
]
