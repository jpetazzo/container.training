# Docker Engine and other container engines

* We are going to cover the architecture of the Docker Engine.

* We will also present other container engines.

---

class: pic

## Docker Engine external architecture

![](images/docker-engine-architecture.svg)

---

## Docker Engine external architecture

* The Engine is a daemon (service running in the background).

* All interaction is done through a REST API exposed over a socket.

* On Linux, the default socket is a UNIX socket: `/var/run/docker.sock`.

* We can also use a TCP socket, with optional mutual TLS authentication.

* The `docker` CLI communicates with the Engine over the socket.

Note: strictly speaking, the Docker API is not fully REST.

Some operations (e.g. dealing with interactive containers
and log streaming) don't fit the REST model.
 
---

class: pic

## Docker Engine internal architecture

![](images/dockerd-and-containerd.png)

---

## Docker Engine internal architecture

* Up to Docker 1.10: the Docker Engine is one single monolithic binary.

* Starting with Docker 1.11, the Engine is split into multiple parts:

  - `dockerd` (REST API, auth, networking, storage)

  - `containerd` (container lifecycle, controlled over a gRPC API)

  - `containerd-shim` (per-container; does almost nothing but allows to restart the Engine without restarting the containers)

  - `runc` (per-container; does the actual heavy lifting to start the container)

* Some features (like image and snapshot management) are progressively being pushed from `dockerd` to `containerd`.

For more details, check [this short presentation by Phil Estes](https://www.slideshare.net/PhilEstes/diving-through-the-layers-investigating-runc-containerd-and-the-docker-engine-architecture).

---

## Other container engines

The following list is not exhaustive.

Furthermore, we limited the scope to Linux containers.

We can also find containers (or things that look like containers) on other platforms
like Windows, macOS, Solaris, FreeBSD ...

---

## LXC

* The venerable ancestor (first released in 2008).

* Docker initially relied on it to execute containers.

* No daemon; no central API.

* Each container is managed by a `lxc-start` process.

* Each `lxc-start` process exposes a custom API over a local UNIX socket, allowing to interact with the container.

* No notion of image (container filesystems have to be managed manually).

* Networking has to be set up manually.

---

## LXD

* Re-uses LXC code (through liblxc).

* Builds on top of LXC to offer a more modern experience.

* Daemon exposing a REST API.

* Can manage images, snapshots, migrations, networking, storage.

* "offers a user experience similar to virtual machines but using Linux containers instead."

---

## CRI-O

* Designed to be used with Kubernetes as a simple, basic runtime.

* Compares to `containerd`.

* Daemon exposing a gRPC interface.

* Controlled using the CRI API (Container Runtime Interface defined by Kubernetes).

* Needs an underlying OCI runtime (e.g. runc).

* Handles storage, images, networking (through CNI plugins).

We're not aware of anyone using it directly (i.e. outside of Kubernetes).

---

## systemd

* "init" system (PID 1) in most modern Linux distributions.

* Offers tools like `systemd-nspawn` and `machinectl` to manage containers.

* `systemd-nspawn` is "In many ways it is similar to chroot(1), but more powerful".

* `machinectl` can interact with VMs and containers managed by systemd.

* Exposes a DBUS API.

* Basic image support (tar archives and raw disk images).

* Network has to be set up manually.

---

## Kata containers

* OCI-compliant runtime.

* Fusion of two projects: Intel Clear Containers and Hyper runV.

* Run each container in a lightweight virtual machine.

* Requires running on bare metal *or* with nested virtualization.

---

## gVisor

* OCI-compliant runtime.

* Implements a subset of the Linux kernel system calls.

* Written in go, uses a smaller subset of system calls.

* Can be heavily sandboxed.

* Can run in two modes:

  * KVM (requires bare metal or nested virtualization),

  * ptrace (no requirement, but slower).

---

## Overall ...

* The Docker Engine is very developer-centric:

  - easy to install

  - easy to use

  - no manual setup

  - first-class image build and transfer

* As a result, it is a fantastic tool in development environments.

* On servers:

  - Docker is a good default choice

  - If you use Kubernetes, the engine doesn't matter
