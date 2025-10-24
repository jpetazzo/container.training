
class: title

# Understanding Docker images

![image](images/title-understanding-docker-images.png)

---

## Objectives

In this section, we will explain:

* What is an image.

* What is a layer.

* The various image namespaces.

* How to search and download images.

* Image tags and when to use them.

---

## What is an image?

* Image = files + metadata

* These files form the root filesystem of our container.

* The metadata can indicate a number of things, e.g.:

  * the author of the image
  * the command to execute in the container when starting it
  * environment variables to be set
  * etc.

* Images are made of *layers*, conceptually stacked on top of each other.

* Each layer can add, change, and remove files and/or metadata.

* Images can share layers to optimize disk usage, transfer times, and memory use.

---

## Example for a Java webapp

Each of the following items will correspond to one layer:

* CentOS base layer
* Packages and configuration files added by our local IT
* JRE
* Tomcat
* Our application's dependencies
* Our application code and assets
* Our application configuration

(Note: app config is generally added by orchestration facilities.)

---

class: pic

## The read-write layer

![layers](images/container-layers.jpg)

---

## Differences between containers and images

* An image is a read-only filesystem.

* A container is an encapsulated set of processes,

  running in a read-write copy of that filesystem.

* To optimize container boot time, *copy-on-write* is used
  instead of regular copy.

* `docker run` starts a container from a given image.

---

class: pic

## Multiple containers sharing the same image

![layers](images/sharing-layers.jpg)

---

## Comparison with object-oriented programming

* Images are conceptually similar to *classes*.

* Layers are conceptually similar to *inheritance*.

* Containers are conceptually similar to *instances*.

---

## Wait a minute...

If an image is read-only, how do we change it?

* We don't.

* We create a new container from that image.

* Then we make changes to that container.

* When we are satisfied with those changes, we transform them into a new layer.

* A new image is created by stacking the new layer on top of the old image.

* This can be automated by writing a `Dockerfile` and then running `docker build`.

---

## Images namespaces

There are three namespaces:

* Official images on the Docker Hub

    e.g. `ubuntu`, `busybox` ...

* User (and organizations) images on the Docker Hub

    e.g. `jpetazzo/clock`

* Images on registries that are NOT the Docker Hub

    e.g. `registry.example.com:5000/my-private/image`

Let's explain each of them.

---

## Root namespace

The root namespace is for official images.

They are gated by Docker Inc.

They are generally authored and maintained by third parties.

Those images include:

* Small, "swiss-army-knife" images like busybox.

* Distro images to be used as bases for your builds, like ubuntu, fedora...

* Ready-to-use components and services, like redis, postgresql...

* Over 150 at this point!

---

## User namespace

The user namespace holds images for Docker Hub users and organizations.

For example:

```bash
jpetazzo/clock
```

The Docker Hub user is:

```bash
jpetazzo
```

The image name is:

```bash
clock
```

---

## Self-hosted namespace

This namespace holds images which are not hosted on Docker Hub, but on third
party registries.

They contain the hostname (or IP address), and optionally the port, of the
registry server.

For example:

```bash
localhost:5000/wordpress
```

* `localhost:5000` is the host and port of the registry
* `wordpress` is the name of the image

Other examples:

```bash
quay.io/coreos/etcd
gcr.io/google-containers/hugo
```

---

## How do you store and manage images?

Images can be stored:

* On your Docker host.
* In a Docker registry.

You can use the Docker client to download (pull) or upload (push) images.

To be more accurate: you can use the Docker client to tell a Docker Engine
to push and pull images to and from a registry.

---

## Showing current images

Let's look at what images are on our host now.

```bash
$ docker images
REPOSITORY       TAG       IMAGE ID       CREATED         SIZE
fedora           latest    ddd5c9c1d0f2   3 days ago      204.7 MB
centos           latest    d0e7f81ca65c   3 days ago      196.6 MB
ubuntu           latest    07c86167cdc4   4 days ago      188 MB
redis            latest    4f5f397d4b7c   5 days ago      177.6 MB
postgres         latest    afe2b5e1859b   5 days ago      264.5 MB
alpine           latest    70c557e50ed6   5 days ago      4.798 MB
debian           latest    f50f9524513f   6 days ago      125.1 MB
busybox          latest    3240943c9ea3   2 weeks ago     1.114 MB
training/namer   latest    902673acc741   9 months ago    289.3 MB
jpetazzo/clock   latest    12068b93616f   12 months ago   2.433 MB
```

---

## Downloading images

There are two ways to download images.

* Explicitly, with `docker pull`.

* Implicitly, when executing `docker run` and the image is not found locally.

---

## Pulling an image

```bash
$ docker pull debian:jessie
Pulling repository debian
b164861940b8: Download complete
b164861940b8: Pulling image (jessie) from debian
d1881793a057: Download complete
```

* As seen previously, images are made up of layers.

* Docker has downloaded all the necessary layers.

* In this example, `:jessie` indicates which exact version of Debian
  we would like.

  It is a *version tag*.

---

## Image and tags

* Images can have tags.

* Tags define image versions or variants.

* `docker pull ubuntu` will refer to `ubuntu:latest`.

* The `:latest` tag is generally updated often.

---

## When to (not) use tags

Don't specify tags:

* When doing rapid testing and prototyping.
* When experimenting.
* When you want the latest version.

Do specify tags:

* When recording a procedure into a script.
* When going to production.
* To ensure that the same version will be used everywhere.
* To ensure repeatability later.

This is similar to what we would do with `pip install`, `npm install`, etc.

---

class: extra-details

## Multi-arch images

- An image can support multiple architectures

- More precisely, a specific *tag* in a given *repository* can have either:

  - a single *manifest* referencing an image for a single architecture

  - a *manifest list* (or *fat manifest*) referencing multiple images

- In a *manifest list*, each image is identified by a combination of:

  - `os` (linux, windows)

  - `architecture` (amd64, arm, arm64...)

  - optional fields like `variant` (for arm and arm64), `os.version` (for windows)

---

class: extra-details

## Working with multi-arch images

- The Docker Engine will pull "native" images when available

  (images matching its own os/architecture/variant)

- We can ask for a specific image platform with `--platform`

- The Docker Engine can run non-native images thanks to QEMU+binfmt

  (automatically on Docker Desktop; with a bit of setup on Linux)

---

## Section summary

We've learned how to:

* Understand images and layers.
* Understand Docker image namespacing.
* Search and download images.

???

:EN:Building images
:EN:- Containers, images, and layers
:EN:- Image addresses and tags
:EN:- Finding and transferring images

:FR:Construire des images
:FR:- La différence entre un conteneur et une image
:FR:- La notion de *layer* partagé entre images
