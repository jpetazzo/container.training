# Testing

There are multiple levels of testing:

- unit testing (many small tests that run in isolation),

- integration testing (bigger tests involving multiple components),

- functional or end-to-end testing (even bigger tests involving the whole app).

In this section, we will focus on *unit testing*, where each test case
should (ideally) be completely isolated from other components and system
interaction: no real database, no real backend, *mocks* everywhere.

(For a good discussion on the merits of unit testing, we can read
[Just Say No to More End-to-End Tests](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html).)

Unfortunately, this ideal scenario is easier said than done ...

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

- This leverages the Docker cache: it the code doesn't change, the tests don't need to run

- If the tests require a database or other backend, we can use `docker build --network`

- If the tests fail, the build fails; and no image is generated

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

- It allows to run custom commands

- Unfortunately, nothing to run other Docker images

  (to start a database or a backend that we need to run tests)
