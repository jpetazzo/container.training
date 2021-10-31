# Exercise — Local Cluster

- We want to have our own local Kubernetes cluster

  (we can use Docker Desktop, KinD, minikube... anything will do!)

- Then we want to run a copy of dockercoins on that cluster

- We want to be able to connect to the web UI

  (we can expose the port, or use port-forward, or whatever)

---

## Goal

- Be able to see the dockercoins web UI running on our local cluster

---

## Hints

- On a Mac or Windows machine:

  the easiest solution is probably Docker Desktop

- On a Linux machine:

  the easiest solution is probably KinD or k3d

- To connect to the web UI:

  `kubectl port-forward` is probably the easiest solution

---

## Bonus

- If you already have a local Kubernetes cluster:

  try to run another one!

- Try to use another method than `kubectl port-forward`
