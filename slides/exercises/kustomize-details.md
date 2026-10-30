# Exercise — Kustomize

Scenario: our dev team has given us a set of YAML manifests for their app.

Now we need to make them production-ready.

The app is DockerCoins, on https://github.com/jpetazzo/kubercoins (branch `kustomize`).

We want to write a kustomization to add a bunch of things to the app.

(Without touching the original YAML manifests!)

---

## Requirements

- Improve the reliability of the app by adding replicas

- Expose the `webui` with Ingress or HTTPRoute instead of NodePort

- Add healthchecks

*Try to implement these requirements. Once you're done, check the next slide to make sure you've implemented everything needed. If you're stuck, you can also check the next slide to see hints!*

---

## Detailed requirements

- Make sure that every component has at least 2 replicas

  (except `redis`, which should stay at 1 replica)

- Expose the `webui` with an Ingress or HTTPRoute

  (and change the service to be of type `ClusterIP`)

- Add readiness probes:

  - `httpGet` for `rng`, `hasher`, `webui`

  - `tcpSocket` for `redis`

- Check next slide for bonus round!

---

## Extra features

*Implement these only if they have been covered in class.*

- Spread replicas with anti-affinity rules

- Add pod disruption budgets

- Isolate the app with network policies

- (Anything else that might improve the reliability of the app!)
