# Exercise — Kubernetes Basics

- Connect to one of your Kubernetes clusters

- Check how many nodes your cluster has

- Check which pods are currently running

  (in the whole cluster, across all namespaces)

---

## Running a single pod

- Create a single (standalone) pod using image `jpetazzo/color`

- Get the pod's IP address

- Send a few HTTP requests to the pod

- View the logs of the pod

  (check that your requests show up correctly)

---

## Running a Deployment

- Create a Deployment using image `jpetazzo/color`

- Get the IP address of the corresponding pod

- Send a few hTTP requests to the pod

- View the logs of the pod

---

## Deleting things

- Delete the standalone pod; what happens?

- Delete the Deployment's pod; what happens?

- Delete the Deployment's ReplicaSet; what happens?

- Delete the Deployment; what happens?

- Check that this lab didn't leave any running pod behind
