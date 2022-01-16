# Exercise — Terraform Node Pools

- Write a Terraform configuration to deploy a cluster

- The cluster should have two node pools with autoscaling

- Deploy two apps, each using exclusively one node pool

- Bonus: deploy an app balanced across both node pools

---

## Cluster deployment

- Write a Terraform configuration to deploy a cluster

- We want to have two node pools with autoscaling

- Example for sizing:

  - 4 GB / 1 CPU per node

  - pools of 1 to 4 nodes

---

## Cluster autoscaling

- Deploy an app on the cluster

  (you can use `nginx`, `jpetazzo/color`...)

- Set a resource request (e.g. 1 GB RAM)

- Scale up and verify that the autoscaler kicks in

---

## Pool isolation

- We want to deploy two apps

- The first app should be deployed exclusively on the first pool

- The second app should be deployed exclusively on the second pool

- Check the next slide for hints!

---

## Hints

- One solution involves adding a `nodeSelector` to the pod templates

- Another solution involves adding:

  - `taints` to the node pools

  - matching `tolerations` to the pod templates

---

## Balancing

- Step 1: make sure that the pools are not balanced

- Step 2: deploy a new app, check that it goes to the emptiest pool

- Step 3: update the app so that it balances (as much as possible) between pools
