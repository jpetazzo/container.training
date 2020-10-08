class: title

# Windows Containers

![Container with Windows](images/windows-containers.jpg)

---

## Objectives

At the end of this section, you will be able to:

* Understand Windows Container vs. Linux Container.

* Know about the features of Docker for Windows for choosing architecture.

* Run other container architectures via QEMU emulation.

---

## Are containers *just* for Linux?

Remember that a container must run on the kernel of the OS it's on.

- This is both a benefit and a limitation.
 
  (It makes containers lightweight, but limits them to a specific kernel.)
 
- At its launch in 2013, Docker did only support Linux, and only on amd64 CPUs.

- Since then, many platforms and OS have been added.

  (Windows, ARM, i386, IBM mainframes ...  But no macOS or iOS yet!)

--

- Docker Desktop (macOS and Windows) can run containers for other architectures

  (Check the docs to see how to [run a Raspberry Pi (ARM) or PPC container](https://docs.docker.com/docker-for-mac/multi-arch/)!)

---

## History of Windows containers

- Early 2016, Windows 10 gained support for running Windows binaries in containers.

  - These are known as "Windows Containers"
  
  - Win 10 expects Docker for Windows to be installed for full features

  - These must run in Hyper-V mini-VM's with a Windows Server x64 kernel 

  - No "scratch" containers, so use "Core" and "Nano" Server OS base layers

  - Since Hyper-V is required, Windows 10 Home won't work (yet...)

--

- Late 2016, Windows Server 2016 ships with native Docker support

  - Installed via PowerShell, doesn't need Docker for Windows

  - Can run native (without VM), or with [Hyper-V Isolation](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container)

---

## LCOW (Linux Containers On Windows)

While Docker on Windows is largely playing catch up with Docker on Linux,
it's moving fast; and this is one thing that you *cannot* do on Linux!

- LCOW came with the [2017 Fall Creators Update](https://blog.docker.com/2018/02/docker-for-windows-18-02-with-windows-10-fall-creators-update/).

- It can run Linux and Windows containers side-by-side on Win 10.

- It is no longer necessary to switch the Engine to "Linux Containers".

  (In fact, if you want to run both Linux and Windows containers at the same time,
   make sure that your Engine is set to "Windows Containers" mode!)

--

If you are a Docker for Windows user, start your engine and try this:

```bash
docker pull microsoft/nanoserver:1803
```

(Make sure to switch to "Windows Containers mode" if necessary.)

---

## Run Both Windows and Linux containers

- Run a Windows Nano Server (minimal CLI-only server)

  ```bash
  docker run --rm -it microsoft/nanoserver:1803 powershell
  Get-Process
  exit
  ```

- Run busybox on Linux in LCOW

  ```bash
  docker run --rm --platform linux busybox echo hello
  ```

(Although you will not be able to see them, this will create hidden
Nano and LinuxKit VMs in Hyper-V!)

---

## Did We Say Things Move Fast

- Things keep improving.

- Now `--platform` defaults to `windows`, some images support both:

  - golang, mongo, python, redis, hello-world ... and more being added

  - you should still use `--platform` with multi-os images to be certain

- Windows Containers now support `localhost` accessible containers (July 2018)

- Microsoft (April 2018) added Hyper-V support to Windows 10 Home ...

  ... so stay tuned for Docker support, maybe?!?

---

## Other Windows container options

Most "official" Docker images don't run on Windows yet.

Places to Look:

  - Hub Official: https://hub.docker.com/u/winamd64/

  - Microsoft: https://hub.docker.com/r/microsoft/

---

## SQL Server? Choice of Linux or Windows

- Microsoft [SQL Server for Linux 2017](https://hub.docker.com/r/microsoft/mssql-server-linux/) (amd64/linux)

- Microsoft [SQL Server Express 2017](https://hub.docker.com/r/microsoft/mssql-server-windows-express/) (amd64/windows)

---

## Windows Tools and Tips

- PowerShell [Tab Completion: DockerCompletion](https://github.com/matt9ucci/DockerCompletion)

- Best Shell GUI: [Cmder.net](https://cmder.net/)

- Good Windows Container Blogs and How-To's

  - Docker DevRel [Elton Stoneman, Microsoft MVP](https://blog.sixeyed.com/)

  - Docker Captain [Nicholas Dille](https://dille.name/blog/)

  - Docker Captain [Stefan Scherer](https://stefanscherer.github.io/) 
