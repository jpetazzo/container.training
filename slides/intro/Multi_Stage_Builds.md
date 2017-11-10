# Multi-stage builds

* In the previous example, our final image contain:

  * our `hello` program

  * its source code

  * the compiler

* Only the first one is strictly necessary.

* We are going to see how to obtain an image without the superfluous components.

---

## Multi-stage builds principles

* At any point in our `Dockerfile`, we can add a new `FROM` line.

* This line starts a new stage of our build.

* Each stage can access the files of the previous stages with `COPY --from=...`.

* When a build is tagged (with `docker build -t ...`), the last stage is tagged.

* Previous stages are not discarded: they will be used for caching, and can be referenced.

---

## Multi-stage builds in practice

* Each stage is numbered, starting at `0`

* We can copy a file from a previous stage by indicating its number, e.g.:

  ```dockerfile
  COPY --from=0 /file/from/first/stage /location/in/current/stage
  ```

* We can also name stages, and reference these names:

  ```dockerfile
  FROM golang AS builder
  RUN ...
  FROM alpine
  COPY --from=builder /go/bin/mylittlebinary /usr/local/bin/
  ```

---

## Multi-stage builds for our C program

We will change our Dockerfile to:

* give a nickname to the first stage: `compiler`

* add a second stage using the same `ubuntu` base image

* add the `hello` binary to the second stage

* make sure that `CMD` is in the second stage 

The resulting Dockerfile is on the next slide.

---

## Multi-stage build `Dockerfile`

Here is the final Dockerfile:

```dockerfile
FROM ubuntu AS compiler
RUN apt-get update
RUN apt-get install -y build-essential
COPY hello.c /
RUN make hello
FROM ubuntu
COPY --from=compiler /hello /hello
CMD /hello
```

Let's build it, and check that it works correctly:

```bash
docker build -t hellomultistage .
docker run hellomultistage
```

---

## Comparing single/multi-stage build image sizes

List our images with `docker images`, and check the size of:

- the `ubuntu` base image,

- the single-stage `hello` image,

- the multi-stage `hellomultistage` image.

We can achieve even smaller images if we use smaller base images.

However, if we use common base images (e.g. if we standardize on `ubuntu`),
these common images will be pulled only once per node, so they are
virtually "free."
