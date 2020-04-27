## Declarative vs imperative in Kubernetes

- With Kubernetes, we cannot say: "run this container"

- All we can do is write a *spec* and push it to the API server

  (by creating a resource like e.g. a Pod or a Deployment)

- The API server will validate that spec (and reject it if it's invalid)

- Then it will store it in etcd

- A *controller* will "notice" that spec and act upon it

---

## Reconciling state

- Watch for the `spec` fields in the YAML files later!

- The *spec* describes *how we want the thing to be*

- Kubernetes will *reconcile* the current state with the spec
  <br/>(technically, this is done by a number of *controllers*)

- When we want to change some resource, we update the *spec*

- Kubernetes will then *converge* that resource

???

:EN:- Declarative vs imperative models
:FR:- Modèles déclaratifs et impératifs
