## Versions installed

- Kubernetes 1.10.1
- Docker Engine 18.03.0-ce
- Docker Compose 1.20.1


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

- Kubernetes 1.10.x only validates Docker Engine versions [1.11.2 to 1.13.1 and 17.03.x](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.10.md#external-dependencies)

--

class: extra-details

- Are we living dangerously?

--

class: extra-details

- "Validates" = continuous integration builds

- The Docker API is versioned, and offers strong backward-compatibility

  (If a client uses e.g. API v1.25, the Docker Engine will keep behaving the same way)
