# Security models

In this section, we want to address a few security-related questions:

- What permissions do we need to run containers or a container engine?

- Can we use containers to escalate permissions?

- Can we break out of a container (move from container to host)?

- Is it safe to run untrusted code in containers?

- What about Kubernetes?

---

## Running Docker, containerd, podman...

- In the early days, running containers required root permissions

  (to set up namespaces, cgroups, networking, mount filesystems...)

- Eventually, new kernel features were developed to allow "rootless" operation

  (user namespaces and associated tweaks)

- Rootless requires a little bit of additional setup on the system (e.g. subuid)

  (although this is increasingly often automated in modern distros)

- Docker runs as root by default; Podman runs rootless by default

---

## Advantages of rootless

- Containers can run without any intervention from root

  (no package install, no daemon running as root...)

- Containerized processes run with non-privileged UID

- Container escape doesn't automatically result in full host compromise

- Can isolate workloads by using different UID

---

## Downsides of rootless

- *Relatively* newer (rootless Docker was introduced in 2019)

  - many quirks/issues/limitations in the initial implementations

  - kernel features and other mechanisms were introduced over time

  - they're not always very well documented

- I/O performance (disk, network) is typically lower

  (due to using special mechanisms instead of more direct access)

- Rootless and rootful engines must use different image storage

  (due to UID mapping)

---

## Why not rootless everywhere?

- Not very useful on clusters

  - users shouldn't log into cluster nodes

  - questionable security improvement

  - lower I/O performance

- Not very useful with Docker Desktop / Podman Desktop

  - container workloads are already inside a VM

  - could arguably provide a layer of inter-workload isolation

  - would require new APIs and concepts

---

## Permission escalation

- Access to the Docker socket = root access to the machine
  ```bash
  docker run --privileged -v /:/hostfs -ti alpine
  ```

- That's why by default, the Docker socket access is locked down

  (only accessible by `root` and group `docker`)

- If user `alice` has access to the Docker socket:

  *compromising user `alice` leads to whole host compromise!*

- Doesn't fundamentally change the threat model

  (if `alice` gets compromised in the first place, we're in trouble!)

- Enables new threats (persistence, kernel access...)

---

## Avoiding the problem

- Rootless containers

- Container VM (Docker Desktop, Podman Desktop, Orbstack...)

- Unfortunately: no fine-grained access to the Docker API

  (no way to e.g. disable privileged containers, volume mounts...)

---

## Escaping containers

- Very easy with some features

  (privileged containers, volume mounts, device access)

- Otherwise impossible in theory

  (but of course, vulnerabilities do exist!)

- **Be careful with scripts invoking `docker run`, or Compose files!**

---

## Untrusted code

- Should be safe as long as we're not enabling dangerous features

  (privileged containers, volume mounts, device access, capabilities...)

- Remember that by default, containers can make network calls

  (but see: `--net none` and also `docker network create --internal`)

- And of course, again: vulnerabilities do exist!

---

## What about Kubernetes?

- Ability to run arbitrary pods = dangerous

- But there are multiple safety mechanisms available:

  - Pod Security Settings (limit "dangerous" features)

  - RBAC (control who can do what)

  - webhooks and policy engines for even finer grained control
