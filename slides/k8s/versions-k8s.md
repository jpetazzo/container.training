## Versions installed

- Kubernetes 1.17.2
- Docker Engine 19.03.5
- Docker Compose 1.24.1

<!-- ##VERSION## -->

.exercise[

- Check all installed versions:
  ```bash
  kubectl version
  docker version
  docker-compose -v
  ```

]

---

class: extra-details

## Kubernetes and Docker compatibility

- Kubernetes 1.17 validates Docker Engine version [up to 19.03](https://github.com/kubernetes/kubernetes/pull/84476)

  *however ...*

- Kubernetes 1.15 validates Docker Engine versions [up to 18.09](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md#dependencies)
  <br/>
  (the latest version when Kubernetes 1.14 was released)

- Kubernetes 1.13 only validates Docker Engine versions [up to 18.06](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md#external-dependencies)

- Is it a problem if I use Kubernetes with a "too recent" Docker Engine?

--

class: extra-details

- No!

- "Validates" = continuous integration builds with very extensive (and expensive) testing

- The Docker API is versioned, and offers strong backward-compatibility
  <br/>
  (if a client uses e.g. API v1.25, the Docker Engine will keep behaving the same way)

---

## Kubernetes versioning and cadence

- Kubernetes versions are expressed using *semantic versioning*

  (a Kubernetes version is expressed as MAJOR.MINOR.PATCH)

- There is a new *patch* release whenever needed

  (generally, there is about [2 to 4 weeks](https://github.com/kubernetes/sig-release/blob/master/release-engineering/role-handbooks/patch-release-team.md#release-timing) between patch releases,
  except when a critical bug or vulnerability is found:
  in that case, a patch release will follow as fast as possible)

- There is a new *minor* release approximately every 3 months

- At any given time, 3 *minor* releases are maintained

  (in other words, a given *minor* release is maintained about 9 months)

---

## Kubernetes version compatibility

*Should my version of `kubectl` match exactly my cluster version?*

- `kubectl` can be up to one minor version older or newer than the cluster

  (if cluster version is 1.15.X, `kubectl` can be 1.14.Y, 1.15.Y, or 1.16.Y)

- Things *might* work with larger version differences

   (but they will probably fail randomly, so be careful)

- This is an example of an error indicating version compability issues:
  ```
  error: SchemaError(io.k8s.api.autoscaling.v2beta1.ExternalMetricStatus):
  invalid object doesn't have additional properties
  ```

- Check [the documentation](https://kubernetes.io/docs/setup/release/version-skew-policy/#kubectl) for the whole story about compatibility
