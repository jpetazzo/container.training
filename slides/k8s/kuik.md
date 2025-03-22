# Kube Image Keeper

- Open source solution to improve registry availability

- Not-too-simple, not-too-complex operator

  (nothing "magic" in the way it works)

- Leverages various Kubernetes features

  (CRD, mutation webhooks...)

- Written in Go, with the kubebuilder framework

---

## Registry problems that can happen

- Registry is unavailable or slow

  (e.g. [registry.k8s.io outage in April 2023][registry-k8s-outage])

- Image was deleted from registry

  (accidentally, or by retention policy)

- Registry has pull quotas

  (hello Docker Hub!)

[registry-k8s-outage]: https://github.com/kubernetes/registry.k8s.io/issues/234#issuecomment-1524456564

---

## Registries are hard to monitor

- Most Kubernetes clusters use images from many registries

  (should we continuously monitor all of them?)

- Registry can be up, but image can be missing

  (should we monitor every image individually?)

- Some registries have quotas

  (can we even monitor them without triggering these quotas?)

---

## Can't we mirror registries?

- Not as straightforward as, say, mirroring package repositories

- Requires container engine configuration or rewriting image references

---

## How it works

- A mutating webhook rewrites image references:

  `ghcr.io/foo/bar:lol` → `localhost:7439/ghcr.io/foo/bar:lol`

- `localhost:7439` is served by the kuik-proxy DaemonSet

- It serves images either from a cache, or directly from origin

- The cache is a regular registry running on the cluster

  (it can be stateless, stateful, backed by PVC, object store...)

- Images are put in cache by the kuik-controller

- Images are tracked by a CachedImage Custom Resource

---

## Some diagrams

See diagrams in [this presentation][kuik-slides].

(The full video of the presentation is available [here][kuik-video].)

[kuik-slides]: https://docs.google.com/presentation/d/19eEogm2HFRNTSqr_1ItLf2wZZP34TUl_RHFhwj3RZEY/edit#slide=id.g27e8d88ad7c_0_142

[kuik-video]: https://www.youtube.com/watch?v=W1wcIdn0DHY

---

## Operator (SRE) analysis

*After using kuik in production for a few years...*

- Prevented many outages or quasi-outages

  (e.g. hitting quotas while scaling up or replacing nodes)

- Running in stateless mode is possible but *not recommended*

  (it's mostly for testing and quick deployments!)

- When managing many clusters, it would be nice to share the cache

  (not just to save space, but get better performance for common images)

- Kuik architecture makes it suitable to virtually *any* cluster

  (not tied to a particular distribution, container engine...)

---

## Operator (CRD) analysis

- Nothing "magic"

- The mutating webhook might even be replaced with Kyverno, CEL... in the long run

- The CachedImage CR exposes internal data (reference count, age, etc)

- Leverages kubebuilder (not reinventing too many wheels, hopefully!)

- Leverages existing building blocks (like the image registry)

- Some minor inefficiencies (e.g. double pull when image is not in cache)

- Breaks semantics for `imagePullPolicy: Always` (but [this is tunable][kuik-ippa])

[kuik-ippa]: https://github.com/enix/kube-image-keeper/issues/156#issuecomment-2312966436

???

:EN:- Image retention with Kube Image Keeper
:FR:- Mise en cache des images avec KUIK
