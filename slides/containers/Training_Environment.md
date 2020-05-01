
class: title

# Our training environment

![SSH terminal](images/title-our-training-environment.jpg)

---

## Our training environment

- If you are attending a tutorial or workshop:

  - a VM has been provisioned for each student

- If you are doing or re-doing this course on your own, you can:

  - install Docker locally (as explained in the chapter "Installing Docker")

  - install Docker on e.g. a cloud VM

  - use https://www.play-with-docker.com/ to instantly get a training environment

---

## Our Docker VM

*This section assumes that you are following this course as part of
a tutorial, training or workshop, where each student is given an
individual Docker VM.*

- The VM is created just before the training.

- It will stay up during the whole training.

- It will be destroyed shortly after the training.

- It comes pre-loaded with Docker and some other useful tools.

---

## What *is* Docker?

- "Installing Docker" really means "Installing the Docker Engine and CLI".

- The Docker Engine is a daemon (a service running in the background).

- This daemon manages containers, the same way that a hypervisor manages VMs.

- We interact with the Docker Engine by using the Docker CLI.

- The Docker CLI and the Docker Engine communicate through an API.

- There are many other programs and client libraries which use that API.

---

## Why don't we run Docker locally?

- We are going to download container images and distribution packages.

- This could put a bit of stress on the local WiFi and slow us down.

- Instead, we use a remote VM that has a good connectivity

- In some rare cases, installing Docker locally is challenging:

  - no administrator/root access (computer managed by strict corp IT)

  - 32-bit CPU or OS

  - old OS version (e.g. CentOS 6, OSX pre-Yosemite, Windows 7)

- It's better to spend time learning containers than fiddling with the installer!

---

## Connecting to your Virtual Machine

You need an SSH client.

* On OS X, Linux, and other UNIX systems, just use `ssh`:

```bash
$ ssh <login>@<ip-address>
```

* On Windows, if you don't have an SSH client, you can download:

  * Putty (www.putty.org)

  * Git BASH (https://git-for-windows.github.io/)

  * MobaXterm (https://mobaxterm.mobatek.net/)

---

## Checking your Virtual Machine

Once logged in, make sure that you can run a basic Docker command:

.small[
```bash
$ docker version
Client:
 Version:       18.03.0-ce
 API version:   1.37
 Go version:    go1.9.4
 Git commit:    0520e24
 Built:         Wed Mar 21 23:10:06 2018
 OS/Arch:       linux/amd64
 Experimental:  false
 Orchestrator:  swarm

Server:
 Engine:
  Version:      18.03.0-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.4
  Git commit:   0520e24
  Built:        Wed Mar 21 23:08:35 2018
  OS/Arch:      linux/amd64
  Experimental: false
```
]

If this doesn't work, raise your hand so that an instructor can assist you!

???

:EN:Container concepts
:FR:Premier contact avec les conteneurs

:EN:- What's a container engine?
:FR:- Qu'est-ce qu'un *container engine* ?
