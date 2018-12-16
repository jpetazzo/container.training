## Versions installed

- Kubernetes 1.13.0
- Docker Engine 18.09.0
- Docker Compose 1.21.1

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

- Kubernetes 1.13.x only validates Docker Engine versions [up to 18.06](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md#external-dependencies)

--

class: extra-details

- Are we living dangerously?

--

class: extra-details

- No!

- "Validates" = continuous integration builds with very extensive (and expensive) testing

- The Docker API is versioned, and offers strong backward-compatibility

  (If a client uses e.g. API v1.25, the Docker Engine will keep behaving the same way)
