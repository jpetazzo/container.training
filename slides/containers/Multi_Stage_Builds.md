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

## Removing unnecessary files

Various techniques are available to obtain smaller images:

- collapsing layers,

- adding binaries that are built outside of the Dockerfile,

- squashing the final image,

- multi-stage builds.

Let's review them quickly.

---

## Collapsing layers

You will frequently see Dockerfiles like this:

```dockerfile
FROM ubuntu
RUN apt-get update && apt-get install xxx && ... && apt-get remove xxx && ...
```

Or the (more readable) variant:

```dockerfile
FROM ubuntu
RUN apt-get update \
 && apt-get install xxx \
 && ... \
 && apt-get remove xxx \
 && ...
```

This `RUN` command gives us a single layer.

The files that are added, then removed in the same layer, do not grow the layer size.

---

## Collapsing layers: pros and cons

Pros:

- works on all versions of Docker

- doesn't require extra tools

Cons:

- not very readable

- some unnecessary files might still remain if the cleanup is not thorough

- that layer is expensive (slow to build)

---

## Building binaries outside of the Dockerfile

This results in a Dockerfile looking like this:

```dockerfile
FROM ubuntu
COPY xxx /usr/local/bin
```

Of course, this implies that the file `xxx` exists in the build context.

That file has to exist before you can run `docker build`.

For instance, it can:

- exist in the code repository,
- be created by another tool (script, Makefile...),
- be created by another container image and extracted from the image.

See for instance the [busybox official image](https://github.com/docker-library/busybox/blob/fe634680e32659aaf0ee0594805f74f332619a90/musl/Dockerfile) or this [older busybox image](https://github.com/jpetazzo/docker-busybox).

---

## Building binaries outside: pros and cons

Pros:

- final image can be very small

Cons:

- requires an extra build tool

- we're back in dependency hell and "works on my machine"

Cons, if binary is added to code repository:

- breaks portability across different platforms

- grows repository size a lot if the binary is updated frequently

---

## Squashing the final image

The idea is to transform the final image into a single-layer image.

This can be done in (at least) two ways.

- Activate experimental features and squash the final image:
  ```bash
  docker image build --squash ...
  ```

- Export/import the final image.
  ```bash
  docker build -t temp-image .
  docker run --entrypoint true --name temp-container temp-image
  docker export temp-container | docker import - final-image
  docker rm temp-container
  docker rmi temp-image
  ```

---

## Squashing the image: pros and cons

Pros:

- single-layer images are smaller and faster to download

- removed files no longer take up storage and network resources

Cons:

- we still need to actively remove unnecessary files

- squash operation can take a lot of time (on big images)

- squash operation does not benefit from cache
  <br/>
  (even if we change just a tiny file, the whole image needs to be re-squashed)

---

## Multi-stage builds

Multi-stage builds allow us to have multiple *stages*.

Each stage is a separate image, and can copy files from previous stages.

We're going to see how they work in more detail.

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

???

:EN:Optimizing our images and their build process
:EN:- Leveraging multi-stage builds

:FR:Optimiser les images et leur construction
:FR:- Utilisation d'un *multi-stage build*
