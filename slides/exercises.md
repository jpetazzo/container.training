## Exercises

- At the end of each day, we'll suggest a few more in-depth exercises

- Try to complete them (either at the end of the day, or later, if you can!)

- The exercises should be very quick for someone who already knows Kubernetes

- But they can be more challenging if they concern parts that you haven't used yet!

---

## Day 1

- Deploy a local Kubernetes cluster if you don't already have one

  (you can use Docker Desktop, KinD, minikube... whatever you like)

- Deploy dockercoins on that cluster

  (feel free to use the YAML file for convenience)

- Connect to the web UI in your browser

  (you can expose the port, or use port-forward, or anything you like)

- Scale up dockercoins

---

## Day 2

- Add the Kubernetes dashboard to your local cluster

- Make sure that dockercoins is deployed in a specific namespace

- Use the dashboard to view that namespace in read-only mode

  (hint: you'll need a service account, rolebinding, and token)

- Tweak permissions so that you can scale deployments in that namespace

- Add an ingress controller to your local cluster

- Configure an ingress resource to access the web UI with `dockercoins.localdev.me`

  (`\*.localdev.me` resolves to 127.0.0.1)

---

## Day 3

- Create a Helm chart to deploy a generic microservice

  (using `helm create` to get a generic chart and tweaking that chart)

- Deploy dockercoins by instanciating that chart multiple times

  (one time per service, so 5 times total)

- Create a "meta" Helm chart to install the 5 components of dockercoins

  (using chart dependencies and aliases)

- Bonus: use Bitnami's redis chart for the dockercoins redis component

---

## Day 4

- Deploy a Kubernetes cluster with multiple nodes

  (you can use something like KinD, k3d, or even a managed k8s)

- If the cluster doesn't already have a storage class, add one

  (for instance, by using OpenEBS)

- Deploy the Consul or the PostgreSQL example

- Destroy a node and:

  - verify the failover behavior (for Consul)

  - trigger the failover behavior (for PostgreSQL)
