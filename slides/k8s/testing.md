# Testing

There are multiple levels of testing. At this point we will focus on

*unit-testing*, ([Just Say No to More End-to-End Tests](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html))

where system interaction are ideally *mocked* everywhere (no real database, no real backend).

Sadly this is easier said that to be done...

---
## Multi-stage build

```dockerfile
FROM <baseimage>
RUN <install dependencies>
COPY <code>
RUN <build code>
RUN <install test dependencies>
COPY <test data sets and fixtures>
RUN <unit tests>
FROM <baseimage>
RUN <install dependencies>
COPY <code>
RUN <build code>
CMD, EXPOSE ...
```

- If code don't change, test don't run, leveraging the docker cache

- Could use `docker build --network` to make database or backend available during build

- But no artifact(image) generated if build fails
---
## Docker Compose

```yaml
version: 3
service:
  project:
    image: my_image_name
    build:
      context: .
      target: dev

  database:
    image: redis
  backend:
    image: backend

```
+

```shell
docker-compose build && docker-compose run project pytest -v
```

---
## Skaffold/Container-structure-test

- The `test` field of the `skaffold.yaml` instructs skaffold to run test against your image.

- It uses the [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test)

- It allows to run custom command

- Sadly nothing to run other docker image to make a database or a backend reachable
