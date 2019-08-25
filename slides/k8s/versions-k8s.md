## Versions installed

- Kubernetes 1.15.3
- Docker Engine 19.03.1
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

  (If a client uses e.g. API v1.25, the Docker Engine will keep behaving the same way)
