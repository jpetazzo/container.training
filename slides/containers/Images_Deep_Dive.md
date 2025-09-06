# Deep Dive Into Images

- Image = files (layers) + metadata (configuration)

- Layers = regular tar archives

  (potentially with *whiteouts*)

- Configuration = everything needed to run the container

  (e.g. Cmd, Env, WorkdingDir...)

---

## Image formats

- Docker image [v1] (no longer used, except in `docker save` and `docker load`)

- Docker image v1.1 (IDs are now hashes instead of random values)

- Docker image [v2] (multi-arch support; content-addressable images)

- [OCI image format][oci] (almost the same, except for media types)

[v1]: https://github.com/moby/docker-image-spec?tab=readme-ov-file
[v2]: https://github.com/distribution/distribution/blob/main/docs/content/spec/manifest-v2-2.md
[oci]: https://github.com/opencontainers/image-spec/blob/main/spec.md

---

## OCI images

- Manifest = JSON document

- Used by container engines to know "what should I download to unpack this image?"

- Contains references to blobs, identified by their sha256 digest + size

  - config (single sha256 digest)

  - layers (list of sha256 digests)

- Also annotations (key/values)

- It's also possible to have a manifest list, or "fat manifest"

  (which lists multiple manifests; this is used for multi-arch support)

---

## Config blob

- Also a JSON document

- `architecture` string (e.g. `amd64`)

- `config` object

  Cmd, Entrypoint, Env, ExposedPorts, StopSignal, User, Volumes, WorkingDir

- `history` list

  purely informative; shown with e.g. `docker history`

- `rootfs` object

  `type` (always `layers`) + list of "diff ids"

---

class: extra-details

## Layers vs layers

- The image configuration contains digests of *uncompressed layers*

- The image manifest contains digests of *compressed layers*

  (layer blobs in the registry can be tar, tar+gzip, tar+zstd)

---

## Layer format

- Layer = completely normal tar archive

- When a file is added or modified, it is added to the archive

  (note: trivial changes, e.g. permissions, require to re-add the whole file!)

- When a file is deleted, a *whiteout* file is created

  e.g. `rm hello.txt` results in a file named `.wh.hello.txt`

- Files starting with `.wh.` are forbidden in containers

- There is a special file, `.wh..wh..opq`, which means "remove all siblings"

  (optimization to completely empty a directory)

- See [layer specification](https://github.com/opencontainers/image-spec/blob/main/layer.md) for details

---

class: extra-details

## Origin of layer format

- The initial storage driver for Docker was AUFS

- AUFS is out-of-tree but Debian and Ubuntu included it

  (they used it for live CD / live USB boot)

- It meant that Docker could work out of the box on these distros

- Later, Docker added support for other systems

  (devicemapper thin provisioning, btrfs, overlay...)

- Today, overlay is the best compromise for most use-cases

---

## Inspecting images

- `skopeo` can copy images between different places

  (registries, Docker Engine, local storage as used by podman...)

- Example:
  ```bash
  skopeo copy docker://alpine oci:/tmp/alpine.oci
  ```

- The image manifest will be in `/tmp/alpine.oci/index.json`

- Blobs (image configuration and layers) will be in `/tmp/alpine.oci/blobs/sha256`

- Note: as of version 1.20, `skopeo` doesn't handle extensions like stargz yet

  (copying stargz images won't transfer the special index blobs)

---

## Layer surgery

Here is an example of how to manually edit an image.

https://github.com/jpetazzo/layeremove

It removes a specific layer from an image.

Note: it would be better to use a buildkit cache mount instead.

(This is just an educative example!)

---

## Stargz

- [Stargz] = Seekable Tar Gz, or "stargazer"

- Goal: start a container *before* its image has been fully downloaded

- Particularly useful for huge images that take minutes to download

- Also known as "streamable images" or "lazy loading"

- Alternative: [SOCI]

[stargz]: https://github.com/containerd/stargz-snapshotter
[SOCI]: https://github.com/awslabs/soci-snapshotter

---

## Stargz architecture

- Combination of:

  - a backward-compatible extension to the OCI image format

  - a containerd *snapshotter*

    (=containerd component responsible for managing container and image storage)

  - tooling to create, convert, optimize images

- Installation requires:

  - running the snapshotter daemon

  - configuring containerd

  - building new images or converting the existing ones

---

## Stargz principle

- Normal image layer = tar.gz = gzip(tar(file1, file2, ...))

- Can't access fileN without uncompressing everything before it

- Seekable Tar Gz = gzip(tar(file1)) + gzip(tar(file2)) + ... + index

  (big files can also be chunked)

- Can access individual files

  (and even individual chunks, if needed)

- Downside: lower compression ratio

  (less compression context; extra gzip headers)

---

## Stargz format

- The index mentioned above is stored in separate registry blobs

  (one index for each layer)

- The digest of the index blobs is stored in annotations in normal OCI images

- Fully compatible with existing registries

- Existing container engines will load images transparently

  (without leveraging stargz capabilities)

---

## Stargz limitations

- Tools like `skopeo` will ignore index blobs

  (=copying images across registries will discard stargz capabilities)

- Indexes need to be downloaded before container can be started

  (=still significant start time when there are many files in images)

- Significant latency when accessing a file lazily

  (need to hit the registry, typically with a range header, uncompress file)

- Images can be optimized to pre-load important files
