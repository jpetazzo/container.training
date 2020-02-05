# Advanced Rollout

- In some cases the built-in mechanism of kubernetes is not enough.

- You want more control on the rollout, include a feedback of the monitoring, deploying
on multiple clusters, etc

- Two "main" strategies exist here:

   - canary deployment
   - blue/green deployment

---
## Canary deployment

- focus on one component of the stack

    - deploy a new version of the component close to the production
    - redirect some portion of prod traffic to new version
    - scale up new version, redirect more traffic, checking everything is ok
    - scale down old version
    - move component to component with the same procedure

- That's what kubernetes does by default, but does every components at the same time

- Could be paired with `kubectl wait --for` and applying component sequentially,
    for hand made canary deployement

---
## Blue/Green deployment

- focus on entire stack

    - deploy a new stack
    - check the new stack work as espected
    - put traffic on new stack, rollback if any goes wrong
    - garbage collect the previous infra structure

- there is nothing like that by default in kubernetes

- helm chart with multiple releases is the closest one

- could be paired with ingress feature like `nginx.ingress.kubernetes.io/canary-*`

---
## Not hand-made ?

There is a few additionnal controllers that help achieving those kind of rollout behaviours

They leverage kubernetes API at different levels to achieve this goal.

---
## Spinnaker

- https://www.spinnaker.io

- Help to deploy the same app on multiple cluster.

- Is able to analyse rollout status (canary analysis) and correlate it to monitoring

- Rollback if anything goes wrong

- also support Blue/Green

- Configuration done via UI

---
## Argo-rollout

- https://github.com/argoproj/argo-rollouts

- Replace your deployments with CRD (Custom Resource Definition) "deployment-like"

- Full control via CRDs

- BlueGreen and Canary deployment
