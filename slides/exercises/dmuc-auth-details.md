# Exercise — enable auth

- We want to enable authentication and authorization

- Checklist:

  - non-privileged user can deploy in their namespace
    <br/>(and nowhere else)

  - each controller uses its own key, certificate, and identity

  - each node uses its own key, certificate, and identity

  - Service Accounts work properly

- See next slide for help / hints!

---

## Checklist

- Generate keys, certs, and kubeconfig for everything that needs them

  (cluster admin, cluster user, controller manager, scheduler, kubelet)

- Reconfigure and restart each component to use its new identity

- Turn on `RBAC` and `Node` authorizers on the API server

- Check that everything works properly

  (e.g. that you can create and scale a Deployment using the "cluster user" identity)
