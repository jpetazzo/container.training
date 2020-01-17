## Versions installed

- Kubernetes 1.17.1
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
