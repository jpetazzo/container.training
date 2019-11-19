
class: title

# Installing Docker

![install](images/title-installing-docker.jpg)

---

## Objectives

At the end of this lesson, you will know:

* How to install Docker.

* When to use `sudo` when running Docker commands.

*Note:* if you were provided with a training VM for a hands-on
tutorial, you can skip this chapter, since that VM already
has Docker installed, and Docker has already been setup to run
without `sudo`.

---

## Installing Docker

There are many ways to install Docker.

We can arbitrarily distinguish:

* Installing Docker on an existing Linux machine (physical or VM)

* Installing Docker on macOS or Windows

* Installing Docker on a fleet of cloud VMs

---

## Installing Docker on Linux

* The recommended method is to install the packages supplied by Docker Inc :

  - add Docker Inc.'s package repositories to your system configuration

  - install the Docker Engine

* Detailed installation instructions (distro by distro) are available on:

  https://docs.docker.com/engine/installation/

* You can also install from binaries (if your distro is not supported):

  https://docs.docker.com/engine/installation/linux/docker-ce/binaries/

* To quickly setup a dev environment, Docker provides a convenience install script:

  ```bash
  curl -fsSL get.docker.com | sh
  ```

---

class: extra-details

## Docker Inc. packages vs distribution packages

* Docker Inc. releases new versions monthly (edge) and quarterly (stable)

* Releases are immediately available on Docker Inc.'s package repositories

* Linux distros don't always update to the latest Docker version

  (Sometimes, updating would break their guidelines for major/minor upgrades)

* Sometimes, some distros have carried packages with custom patches

* Sometimes, these patches added critical security bugs ☹

* Installing through Docker Inc.'s repositories is a bit of extra work …

  … but it is generally worth it!

---

## Installing Docker on macOS and Windows

* On macOS, the recommended method is to use Docker Desktop for Mac:

  https://docs.docker.com/docker-for-mac/install/

* On Windows 10 Pro, Enterprise, and Education, you can use Docker Desktop for Windows:

  https://docs.docker.com/docker-for-windows/install/

* On older versions of Windows, you can use the Docker Toolbox:

  https://docs.docker.com/toolbox/toolbox_install_windows/

* On Windows Server 2016, you can also install the native engine:

  https://docs.docker.com/install/windows/docker-ee/

---

## Docker Desktop

* Special Docker edition available for Mac and Windows

* Integrates well with the host OS:

  * installed like normal user applications on the host

  * provides user-friendly GUI to edit Docker configuration and settings

* Only support running one Docker VM at a time ...

  ... but we can use `docker-machine`, the Docker Toolbox, VirtualBox, etc. to get a cluster.

---

class: extra-details

## Docker Desktop internals

* Leverages the host OS virtualization subsystem

  (e.g. the [Hypervisor API](https://developer.apple.com/documentation/hypervisor) on macOS)

* Under the hood, runs a tiny VM

  (transparent to our daily use)

* Accesses network resources like normal applications

  (and therefore, plays better with enterprise VPNs and firewalls)

* Supports filesystem sharing through volumes

  (we'll talk about this later)

---

## Running Docker on macOS and Windows

When you execute `docker version` from the terminal:

* the CLI connects to the Docker Engine over a standard socket,
* the Docker Engine is, in fact, running in a VM,
* ... but the CLI doesn't know or care about that,
* the CLI sends a request using the REST API,
* the Docker Engine in the VM processes the request,
* the CLI gets the response and displays it to you.

All communication with the Docker Engine happens over the API.

This will also allow to use remote Engines exactly as if they were local.

---

## Important PSA about security

* If you have access to the Docker control socket, you can take over the machine

  (Because you can run containers that will access the machine's resources)

* Therefore, on Linux machines, the `docker` user is equivalent to `root`

* You should restrict access to it like you would protect `root`

* By default, the Docker control socket belongs to the `docker` group

* You can add trusted users to the `docker` group

* Otherwise, you will have to prefix every `docker` command with `sudo`, e.g.:

  ```bash
  sudo docker version
  ```
