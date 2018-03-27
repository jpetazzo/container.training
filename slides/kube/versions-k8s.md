## Versions installed

- Kubernetes 1.9.6 (but 1.10 is about to come out!)
- Docker Engine 18.03.0-ce
- Docker Compose 1.18.0


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

- Kubernetes only validates Docker Engine versions 1.11.2, 1.12.6, 1.13.1, and 17.03.2

--

class: extra-details

- Are we living dangerously?

--

class: extra-details

- "Validates" = continuous integration builds

- The Docker API is versioned, and offers strong backward-compatibility

  (If a client uses e.g. API v1.25, the Docker Engine will keep behaving the same way)
