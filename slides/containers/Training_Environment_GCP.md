
class: title

# Our training environment

![GCP shell](images/title-our-training-environment-gcp-shell.png)

---

## Our training environment

- If you are attending a tutorial or workshop:

  - a temporary [GCP](https://cloud.google.com) account has been provided for you

  - login with this username & password (incognito browser)

  - find the shell and editor interfaces, we will use those

- If you are doing or re-doing this course on your own, you can:

  - install Docker locally (as explained in the chapter "Installing Docker")

  - install Docker on e.g. a cloud VM

  - use http://www.play-with-docker.com/ to instantly get a training environment

---

## Our (Docker enabled) GCP Shell

*This section assumes that you are following this course as part of
a tutorial, training or workshop, where each student is given an
individual Docker VM.*

- The temporary GCP account is created just before the training.

- It will remain available during the training.

- It will be destroyed shortly after the training.

- It comes pre-loaded with Docker and some other useful tools.

- It does not require much bandwidth (no install downloads).

---

## What *is* Docker?

- "Installing Docker" really means "Installing the Docker Engine and CLI".

- The Docker Engine is a daemon (a service running in the background).

- This daemon manages containers, the same way that an hypervisor manages VMs.

- We interact with the Docker Engine by using the Docker CLI.

- The Docker CLI and the Docker Engine communicate through an API.

- There are many other programs, and many client libraries, to use that API.

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

class: pic

## Access the GCP Shell from your Browser

[![GCP shell](images/gcp-shell-setup.gif)](images/gcp-shell-setup.gif)

---

## Checking your Docker environment

Once logged in, make sure that you can run a basic Docker command:

.small[
```bash
$ docker version
Client:
 Version:      18.03.1-ce
 API version:  1.37
 Go version:   go1.9.5
 Git commit:   9ee9f40
 Built:        Thu Apr 26 07:17:14 2018
 OS/Arch:      linux/amd64
 Experimental: false
 Orchestrator: swarm
Server:
 Engine:
  Version:      18.03.1-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.5
  Git commit:   9ee9f40
  Built:        Thu Apr 26 07:15:24 2018
  OS/Arch:      linux/amd64
  Experimental: false
```
]

If this doesn't work, raise your hand so that an instructor can assist you!

---

class: pic

## How to edit files *(or `vi, nano, etc`)*

![GCP shell](images/gcp-editor.png)


