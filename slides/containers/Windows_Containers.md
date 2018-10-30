class: title

# Windows Containers

![Container with Windows](images/windows-containers.jpg)

---

## Objectives

At the end of this section, you will be able to:

* Understand Windows Container vs. Linux Container.

* Features of Docker for Windows for choosing architecture.

* Run other container architectures via QEMU emulation.

---

## Are Containers *just* for Linux?

Remember that a container must run on the kernel of the OS it's on

  - This is both a benefit and a limitation. 
  
  - Since 2013 Docker launch, many OS's have added support for the Docker runtime.

  - We can now run more than "amd64/linux": including Windows, ARM, i386, IBM mainframes, and more, but no macOS or iOS yet :/

--

  - Docker Desktop (macOS/Win) has a emulator too for ARM/PPC and others
  
  - Later, try running a [Raspberry Pi (ARM) or PPC container](https://docs.docker.com/docker-for-mac/multi-arch/)

---

## History of Windows Containers

- Early 2016, Windows 10 gained support for running Windows binaries in containers.

  - These are known as "Windows Containers"
  
  - Win 10 expects Docker for Windows to be installed for full features

  - These must run in Hyper-V mini-VM's with a Windows Server x64 kernel 

  - No "scrach" containers, so use "Core" and "Nano" Server OS base layers

  - Since Hyper-V is required, Windows 10 Home won't work (yet...)

--

- Late 2016, Windows Server 2016 ships with native Docker support

  - Installed via PowerShell, doesn't need Docker for Windows

  - Can run native (without VM), or with [Hyper-V Isolation](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container)

---

## Windows Containers Cont.

Windows is largely playing catch up with Linux but moving fast!

You can now do things on Windows you *can't* do on Linux:

LCOW: "Linux Containers on Windows" 

  - Came with the ([Fall 2017 Creators Update](https://blog.docker.com/2018/02/docker-for-windows-18-02-with-windows-10-fall-creators-update/))

  - Run Linux and Windows containers side-by-side on Win 10
  
  - No longer required to switch to "Linux Containers"

--

Docker for Windows Users, Start Your Engines:

  ```bash
    docker pull microsoft/nanoserver:1803
  ```

--

Doh! We need to switch to Windows Containers mode (do that now)

---

## Run Both Windows and Linux containers

- Run a Nano Windows Server (minimal cli-only server)

  ```bash
  docker run --rm -it microsoft/nanoserver:1803 powershell
  Get-Process
  exit
  ```

- Run a Busybox Linux in LCOW

  ```bash
  docker run --rm --platform linux busybox echo hello
  ```

(You'll notice nothing in Hyper-V but they are there, hidden Nano and "LinuxKit" VMs)

---

## Did We Say Things Move Fast

- Things keep improving. Now `--platform` defaults to `windows`, some images support both

  - golang, mongo, python, redis, hello-world, and more being added

  - You should still use `--plaform` with multi-os images to be certain 

- Windows Containers now support `localhost` accessable containers (July 2018)

- Microsoft (April 2018) added Hyper-V support to Windows 10 Home, so stay tuned for Docker support, maybe?!?

---

## Other Windows Container options

Most "official" Docker images don't run on Windows yet

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

- Best Shell GUI: [Cmder.net](http://cmder.net/)

- Good Windows Container Blogs and How-To's

  - Dockers DevRel [Elton Stoneman, Microsoft MVP](https://blog.sixeyed.com/)

  - Docker Captian [Nicholas Dille](https://dille.name/blog/)

  - Docker Captain [Stefan Scherer](https://stefanscherer.github.io/) 
