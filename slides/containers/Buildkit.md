# Buildkit

- "New" backend for Docker builds

  - announced in 2017

  - ships with Docker Engine 18.09

  - enabled by default on Docker Desktop in 2021

- Huge improvements in build efficiency

- 100% compatible with existing Dockerfiles

- New features for multi-arch

- Not just for building container images

---

## Old vs New

- Classic `docker build`:

  - copy whole build context
  - linear execution
  - `docker run` + `docker commit` + `docker run` + `docker commit`...

- Buildkit:

  - copy files only when they are needed; cache them
  - compute dependency graph (dependencies are expressed by `COPY`)
  - parallel execution
  - doesn't rely on Docker, but on internal runner/snapshotter
  - can run in "normal" containers (including in Kubernetes pods)

---

## Parallel execution

- In multi-stage builds, all stages can be built in parallel

  (example: https://github.com/jpetazzo/shpod; [before] and [after])

- Stages are built only when they are necessary

  (i.e. if their output is tagged or used in another necessary stage)

- Files are copied from context only when needed

- Files are cached in the builder

[before]: https://github.com/jpetazzo/shpod/blob/c6efedad6d6c3dc3120dbc0ae0a6915f85862474/Dockerfile
[after]: https://github.com/jpetazzo/shpod/blob/d20887bbd56b5fcae2d5d9b0ce06cae8887caabf/Dockerfile

---

## Turning it on and off

- On recent version of Docker Desktop (since 2021):

  *enabled by default*

- On older versions, or on Docker CE (Linux):

  `export DOCKER_BUILDKIT=1`

- Turning it off:

  `export DOCKER_BUILDKIT=0`

---

## Multi-arch support

- Historically, Docker only ran on x86_64 / amd64

  (Intel/AMD 64 bits architecture)

- Folks have been running it on 32-bit ARM for ages

  (e.g. Raspberry Pi)

- This required a Go compiler and appropriate base images

  (which means changing/adapting Dockerfiles to use these base images)

- Docker [image manifest v2 schema 2][manifest] introduces multi-arch images

  (`FROM alpine` automatically gets the right image for your architecture)

[manifest]: https://docs.docker.com/registry/spec/manifest-v2-2/

---

## Why?

- Raspberry Pi (32-bit and 64-bit ARM)

- Other ARM-based embedded systems (ODROID, NVIDIA Jetson...)

- Apple M1

- AWS Graviton

- Ampere Altra (e.g. on Oracle Cloud)

- ...

---

## Multi-arch builds in a nutshell

Use the `docker buildx build` command:

```bash
docker buildx build … \
       --platform linux/amd64,linux/arm64,linux/arm/v7,linux/386 \
       [--tag jpetazzo/hello --push]
```

- Requires all base images to be available for these platforms

- Must not use binary downloads with hard-coded architectures!

  (streamlining a Dockerfile for multi-arch: [before], [after])

[before]: https://github.com/jpetazzo/shpod/blob/d20887bbd56b5fcae2d5d9b0ce06cae8887caabf/Dockerfile
[after]: https://github.com/jpetazzo/shpod/blob/c50789e662417b34fea6f5e1d893721d66d265b7/Dockerfile

---

## Native vs emulated vs cross

- Native builds:

  *aarch64 machine running aarch64 programs building aarch64 images/binaries*

- Emulated builds:

  *x86_64 machine running aarch64 programs building aarch64 images/binaries*

- Cross builds:

  *x86_64 machine running x86_64 programs building aarch64 images/binaries*

---

## Native

- Dockerfiles are (relatively) simple to write

  (nothing special to do to handle multi-arch; just avoid hard-coded archs)

- Best performance

- Requires "exotic" machines

- Requires setting up a build farm

---

## Emulated

- Dockerfiles are (relatively) simple to write

- Emulation performance can vary

  (from "OK" to "ouch this is slow")

- Emulation isn't always perfect

  (weird bugs/crashes are rare but can happen)

- Doesn't require special machines

- Supports arbitrary architectures thanks to QEMU

---

## Cross

- Dockerfiles are more complicated to write

- Requires cross-compilation toolchains

- Performance is good

- Doesn't require special machines

---

## Native builds

- Requires base images to be available

- To view available architectures for an image:
  ```bash
  regctl manifest get --list <imagename>
  docker manifest inspect <imagename>
  ```

- Nothing special to do, *except* when downloading binaries!

  ```
  https://releases.hashicorp.com/terraform/1.1.5/terraform_1.1.5_linux_`amd64`.zip
  ```

---

## Finding the right architecture

`uname -m` → armv7l, aarch64, i686, x86_64

`GOARCH` (from `go env`) → arm, arm64, 386, amd64

In Dockerfile, add `ARG TARGETARCH` (or `ARG TARGETPLATFORM`)

- `TARGETARCH` matches `GOARCH`

- `TARGETPLAFORM` → linux/arm/v7, linux/arm64, linux/386, linux/amd64

---

class: extra-details

## Welp

Sometimes, binary releases be like:

```
Linux_arm64.tar.gz
Linux_ppc64le.tar.gz
Linux_s390x.tar.gz
Linux_x86_64.tar.gz 
```

This needs a bit of custom mapping.

---

## Emulation

- Leverages `binfmt_misc` and QEMU on Linux

- Enabling:
  ```bash
  docker run --rm --privileged aptman/qus -s -- -p
  ```

- Disabling:
  ```bash
  docker run --rm --privileged aptman/qus -- -r
  ```

- Checking status:
  ```bash
  ls -l /proc/sys/fs/binfmt_misc
  ```

---

class: extra-details

## How it works

- `binfmt_misc` lets us register _interpreters_ for binaries, e.g.:

  - [DOSBox][dosbox] for DOS programs

  - [Wine][wine] for Windows programs

  - [QEMU][qemu] for Linux programs for other architectures

- When we try to execute e.g. a SPARC binary on our x86_64 machine:

  - `binfmt_misc` detects the binary format and invokes `qemu-<arch> the-binary ...`

  - QEMU translates SPARC instructions to x86_64 instructions

  - system calls go straight to the kernel

[dosbox]: https://www.dosbox.com/
[QEMU]: https://www.qemu.org/
[wine]: https://www.winehq.org/

---

class: extra-details

## QEMU registration

- The `aptman/qus` image mentioned earlier contains static QEMU builds

- It registers all these interpreters with the kernel

- For more details, check:

  - https://github.com/dbhi/qus

  - https://dbhi.github.io/qus/

---

## Cross-compilation

- Cross-compilation is about 10x faster than emulation

  (non-scientific benchmarks!)

- In Dockerfile, add:

  `ARG BUILDARCH BUILDPLATFORM TARGETARCH TARGETPLATFORM`

- Can use `FROM --platform=$BUILDPLATFORM <image>`

- Then use `$TARGETARCH` or `$TARGETPLATFORM`

  (e.g. for Go, `export GOARCH=$TARGETARCH`)

- Check [tonistiigi/xx][xx] and [Toni's blog][toni] for some amazing cross tools!

[xx]: https://github.com/tonistiigi/xx
[toni]: https://medium.com/@tonistiigi/faster-multi-platform-builds-dockerfile-cross-compilation-guide-part-1-ec087c719eaf

---

## Checking runtime capabilities

Build and run the following Dockerfile:

```dockerfile
FROM --platform=linux/amd64 busybox AS amd64
FROM --platform=linux/arm64 busybox AS arm64
FROM --platform=linux/arm/v7 busybox AS arm32
FROM --platform=linux/386 busybox AS ia32
FROM alpine
RUN apk add file
WORKDIR /root
COPY --from=amd64 /bin/busybox /root/amd64/busybox
COPY --from=arm64 /bin/busybox /root/arm64/busybox
COPY --from=arm32 /bin/busybox /root/arm32/busybox
COPY --from=ia32 /bin/busybox /root/ia32/busybox
CMD for A in *; do echo "$A => $($A/busybox uname -a)"; done
```

It will indicate which executables can be run on your engine.

---

## More than builds

- Buildkit is also used in other systems:

  - [Earthly] - generic repeatable build pipelines

  - [Dagger] - CICD pipelines that run anywhere

  - and more!

[Earthly]: https://earthly.dev/
[Dagger]: https://dagger.io/
