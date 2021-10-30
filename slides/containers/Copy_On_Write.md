# Copy-on-write filesystems

Container engines rely on copy-on-write to be able
to start containers quickly, regardless of their size.

We will explain how that works, and review some of
the copy-on-write storage systems available on Linux.

---

## What is copy-on-write?

- Copy-on-write is a mechanism allowing to share data.

- The data appears to be a copy, but is only
  a link (or reference) to the original data.

- The actual copy happens only when someone
  tries to change the shared data.

- Whoever changes the shared data ends up
  using their own copy instead of the shared data.

---

## A few metaphors

--

- First metaphor:
  <br/>white board and tracing paper

--

- Second metaphor:
  <br/>magic books with shadowy pages

--

- Third metaphor:
  <br/>just-in-time house building

---

## Copy-on-write is *everywhere*

- Process creation with `fork()`.

- Consistent disk snapshots.

- Efficient VM provisioning.

- And, of course, containers.

---

## Copy-on-write and containers

Copy-on-write is essential to give us "convenient" containers.

- Creating a new container (from an existing image) is "free".

  (Otherwise, we would have to copy the image first.)

- Customizing a container (by tweaking a few files) is cheap.

  (Adding a 1 KB configuration file to a 1 GB container takes 1 KB, not 1 GB.)

- We can take snapshots, i.e. have "checkpoints" or "save points"
  when building images.

---

## AUFS overview

- The original (legacy) copy-on-write filesystem used by first versions of Docker.

- Combine multiple *branches* in a specific order.

- Each branch is just a normal directory.

- You generally have:

  - at least one read-only branch (at the bottom),

  - exactly one read-write branch (at the top).

  (But other fun combinations are possible too!)

---

## AUFS operations: opening a file

- With `O_RDONLY` - read-only access:

  - look it up in each branch, starting from the top

  - open the first one we find

- With `O_WRONLY` or `O_RDWR` - write access:

  - if the file exists on the top branch: open it

  - if the file exists on another branch: "copy up"
    <br/>
    (i.e. copy the file to the top branch and open the copy)

  - if the file doesn't exist on any branch: create it on the top branch

That "copy-up" operation can take a while if the file is big!

---

## AUFS operations: deleting a file

- A *whiteout* file is created.

- This is similar to the concept of "tombstones" used in some data systems.

```
 # docker run ubuntu rm /etc/shadow

 # ls -la /var/lib/docker/aufs/diff/$(docker ps --no-trunc -lq)/etc
 total 8
 drwxr-xr-x 2 root root 4096 Jan 27 15:36 .
 drwxr-xr-x 5 root root 4096 Jan 27 15:36 ..
 -r--r--r-- 2 root root    0 Jan 27 15:36 .wh.shadow
```

---

## AUFS performance

- AUFS `mount()` is fast, so creation of containers is quick.

- Read/write access has native speeds.

- But initial `open()` is expensive in two scenarios:

  - when writing big files (log files, databases ...),

  - when searching many directories (PATH, classpath, etc.) over many layers.

- Protip: when we built dotCloud, we ended up putting
  all important data on *volumes*.

- When starting the same container multiple times:

  - the data is loaded only once from disk, and cached only once in memory;

  - but `dentries` will be duplicated.

---

## Device Mapper

Device Mapper is a rich subsystem with many features.

It can be used for: RAID, encrypted devices, snapshots, and more.

In the context of containers (and Docker in particular), "Device Mapper"
means:

"the Device Mapper system + its *thin provisioning target*"

If you see the abbreviation "thinp" it stands for "thin provisioning".

---

## Device Mapper principles

- Copy-on-write happens on the *block* level
  (instead of the *file* level).

- Each container and each image get their own block device.

- At any given time, it is possible to take a snapshot:

  - of an existing container (to create a frozen image),

  - of an existing image (to create a container from it).

- If a block has never been written to:

  - it's assumed to be all zeros,

  - it's not allocated on disk.

(That last property is the reason for the name "thin" provisioning.)

---

## Device Mapper operational details

- Two storage areas are needed:
  one for *data*, another for *metadata*.

- "data" is also called the "pool"; it's just a big pool of blocks.

  (Docker uses the smallest possible block size, 64 KB.)

- "metadata" contains the mappings between virtual offsets (in the
  snapshots) and physical offsets (in the pool).

- Each time a new block (or a copy-on-write block) is written,
  a block is allocated from the pool.

- When there are no more blocks in the pool, attempts to write
  will stall until the pool is increased (or the write operation
  aborted).

- In other words: when running out of space, containers are
  frozen, but operations will resume as soon as space is available.

---

## Device Mapper performance

- By default, Docker puts data and metadata on a loop device
  backed by a sparse file.

- This is great from a usability point of view,
  since zero configuration is needed.

- But it is terrible from a performance point of view:

  - each time a container writes to a new block,
  - a block has to be allocated from the pool,
  - and when it's written to,
  - a block has to be allocated from the sparse file,
  - and sparse file performance isn't great anyway.

- If you use Device Mapper, make sure to put data (and metadata)
  on devices!

---

## BTRFS principles

- BTRFS is a filesystem (like EXT4, XFS, NTFS...) with built-in snapshots.

- The "copy-on-write" happens at the filesystem level.

- BTRFS integrates the snapshot and block pool management features
  at the filesystem level.

  (Instead of the block level for Device Mapper.)

- In practice, we create a "subvolume" and 
  later take a "snapshot" of that subvolume.

  Imagine: `mkdir` with Super Powers and `cp -a` with Super Powers.

- These operations can be executed with the `btrfs` CLI tool.

---

## BTRFS in practice with Docker

- Docker can use BTRFS and its snapshotting features to store container images.

- The only requirement is that `/var/lib/docker` is on a BTRFS filesystem.

  (Or, the directory specified with the `--data-root` flag when starting the engine.)

---

class: extra-details

## BTRFS quirks

- BTRFS works by dividing its storage in *chunks*.

- A chunk can contain data or metadata.

- You can run out of chunks (and get `No space left on device`)
  even though `df` shows space available.
  
  (Because chunks are only partially allocated.)

- Quick fix:

```
 # btrfs filesys balance start -dusage=1 /var/lib/docker
```

---

## Overlay2

- Overlay2 is very similar to AUFS.

- However, it has been merged in "upstream" kernel.

- It is therefore available on all modern kernels.

  (AUFS was available on Debian and Ubuntu, but required custom kernels on other distros.)

- It is simpler than AUFS (it can only have two branches, called "layers").

- The container engine abstracts this detail, so this is not a concern.

- Overlay2 storage drivers generally use hard links between layers.

- This improves `stat()` and `open()` performance, at the expense of inode usage.

---

## ZFS

- ZFS is similar to BTRFS (at least from a container user's perspective).

- Pros:

  - high performance
  - high reliability (with e.g. data checksums)
  - optional data compression and deduplication

- Cons:

  - high memory usage
  - not in upstream kernel

- It is available as a kernel module or through FUSE.

---

## Which one is the best?

- Eventually, overlay2 should be the best option.

- It is available on all modern systems.

- Its memory usage is better than Device Mapper, BTRFS, or ZFS.

- The remarks about *write performance* shouldn't bother you:
  <br/>
  data should always be stored in volumes anyway!

???

:EN:- Copy-on-write filesystems
:EN:- Docker graph drivers
:FR:- Les systèmes de fichiers "copy-on-write"
:FR:- Les "graph drivers" de Docker
