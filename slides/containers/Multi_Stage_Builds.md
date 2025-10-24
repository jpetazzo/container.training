# Reducing image size

* In the previous example, our final image contained:

  * our `hello` program

  * its source code

  * the compiler

* Only the first one is strictly necessary.

* We are going to see how to obtain an image without the superfluous components.

---

## Can't we remove superfluous files with `RUN`?

What happens if we do one of the following commands?

- `RUN rm -rf ...`

- `RUN apt-get remove ...`

- `RUN make clean ...`

--

This adds a layer which removes a bunch of files.

But the previous layers (which added the files) still exist.

---

## Removing files with an extra layer

When downloading an image, all the layers must be downloaded.

| Dockerfile instruction | Layer size | Image size |
| ---------------------- | ---------- | ---------- |
| `FROM ubuntu` | Size of base image | Size of base image |
| `...` | ... | Sum of this layer <br/>+ all previous ones |
| `RUN apt-get install somepackage` | Size of files added <br/>(e.g. a few MB) | Sum of this layer <br/>+ all previous ones |
| `...` | ... | Sum of this layer <br/>+ all previous ones |
| `RUN apt-get remove somepackage` | Almost zero <br/>(just metadata) | Same as previous one |

Therefore, `RUN rm` does not reduce the size of the image or free up disk space.

---

# Multi-stage builds

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

---

class: extra-details

## Build targets

* We can also tag an intermediary stage with the following command:
  ```bash
  docker build --target STAGE --tag NAME
  ```

* This will create an image (named `NAME`) corresponding to stage `STAGE`

* This can be used to easily access an intermediary stage for inspection

  (instead of parsing the output of `docker build` to find out the image ID)

* This can also be used to describe multiple images from a single Dockerfile

  (instead of using multiple Dockerfiles, which could go out of sync)

---

class: extra-details

## Dealing with download caches

* In some cases, our images contain temporary downloaded files or caches

  (examples: packages downloaded by `pip`, Maven, etc.)

* These can sometimes be disabled

  (e.g. `pip install --no-cache-dir ...`)

* The cache can also be cleaned immediately after installing

  (e.g. `pip install ... && rm -rf ~/.cache/pip`)

---

class: extra-details

## Download caches and multi-stage builds

* Download+install packages in a build stage

* Copy the installed packages to a run stage

* Example: in the specific case of Python, use a virtual env

  (install in the virtual env; then copy the virtual env directory)

---

class: extra-details

## Download caches and BuildKit

* BuildKit has a caching feature for run stages

* It can address download caches elegantly

* Example:
  ```bash
  RUN --mount=type=cache,target=/pipcache pip install --cache-dir /pipcache ...
  ```

* The cache won't be in the final image, but it'll persist across builds

???

:EN:Optimizing our images and their build process
:EN:- Leveraging multi-stage builds

:FR:Optimiser les images et leur construction
:FR:- Utilisation d'un *multi-stage build*
