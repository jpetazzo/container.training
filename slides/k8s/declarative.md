## Declarative vs imperative in Kubernetes

- Virtually everything we create in Kubernetes is created from a *spec*

- Watch for the `spec` fields in the YAML files later!

- The *spec* describes *how we want the thing to be*

- Kubernetes will *reconcile* the current state with the spec
  <br/>(technically, this is done by a number of *controllers*)

- When we want to change some resource, we update the *spec*

- Kubernetes will then *converge* that resource
