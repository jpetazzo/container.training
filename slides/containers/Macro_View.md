

class: title

# The Macroscopic View

---

## Macroscopic Items

* The business case for containers

* The problem containers are solving

* What applications need

* What is the OS doing provides?

---

## What do CIOs worry about?

Who are the CIO's customers?

* Business Units: Need Computers to Run Applications
  * Peak Capacity

* CFO: Demanding Budget Justifications
  * Spend Less

---

## History of Solutions

For Each Business Application Buy a Machine

* Buy a machine for each application

  * Big enough for Peak Load (CPU, Memory, Disk)
  
The Age of VMs

* Buy bigger machines and chop them up into logical machines

  * Distribute your applications as VMs theses machines

* Observe what and when the application load  actually is

  * Possibly rebalance be to inform possibly moving

But Maintaining Machines (Bare Metal or VM) is hard (Patches, Packages, Drivers, etc)

---

## What Developers and Ops worry about

* Getting Software deployed

* Mysterious reasons why deployed application doesn't work

    * Developer to Ops:

        * "Hey it works on my development machine..."
        
        * "I don't know why it isn't working for ***you***"

        * "Everything ***looks*** the same"

        * "I have no idea what could be different"  

---

## The History of Software Deployment

Software Deployment is just a reproducible way to install files:

* Cards

* Tapes

* Floppy Disks

* Zip/Tar Files

* Installation "Files" (rpm/deb/msi)

* VM Images

---

## What is the Problem Containers are Solving?

It depends on who you are:

  * For the CIO: Better resource utilization

  * For Ops: Software Distribution
  
  * For the Developer & Ops: Reproducible Environment

<BR><BR>

Ummm, but what exactly are containers....

  * Wait a few more slides...

---

## Macroscopic view: Applications and the OS

Applications:

* What are the inputs/outputs to a program?

The OS:

* What does the OS provide?

---

## What are the inputs/outputs to a program?

Explicitly:
* Command Line Arguments
* Environment Variables
* Standard In
* Standard Out/Err

Implicitly (via the File System):

* Configuration Files
* Other Installed Applications
* Any other files

Also Implicitly

* Memory
* Network

    
---


## What does the OS provide?

* OS Kernel
    * Kernel loded at boot time
        * Sets up disk drives, network cards, other hardware, etc
        * Manages all hardware, processes, memory, etc
    * Kernel Space
        * Low level innards of Kernel (fluid internal API)
        * No direct access by applications of most Kernel functionality


* User Space (userland) Processes
    * Code running outside the Kernel
    * Very stable shim library access from User Space to Kernel Space (Think "fopen")

* The "init" Process
    * User Space Process run after Kernel has booted
    * Always PID 1

---

## OS Processes

* Created when an application is launched
    *  Each has a unique Process ID (PID)

* Provides it its own logical 'view' of all implicit inputs/output when launching app
    * File System ( root directory, / )
    * Memory
    * Network Adaptors
    * Other running processes

---

## What do we mean by "The OS"

Different Linux's

* Ubuntu / Debian; Centos / RHEL; Raspberry Pi; etc

What do they have in common?

* They all have a kernel that provides access to Userland (ie fopen)

* They typically have all the commands (bash, sh, ls, grep, ...)

What may be different?

* May use different versions of the Kernel (4.18, 5.4, ...)
    * Internally different, but providing same Userland API

* Many other bundled commands, packages and package management tools
    * Namely what makes it 'Debian' vs 'Centos'

---

## What might a 'Minimal' Linux be?

You could actually just have:

* A Linux Kernel

* An application (for simplicity a statically linked C program)

* The kernel configured to run that application as its 'init' process

Would you ever do this?

* Why not? 

    * It certainly would be very secure
    
---

## So Finally... What are Containers?

Containers just a Linux process that 'thinks' it is it's own machine

* With its own 'view' of things like:
    * File System ( root directory, / ), Memory, Network Adaptors, Other running processes

* Leverages our understanding that a (logical) Linux Machine is 
    * A kernel
    * A bunch of files ( Maybe a few Environment Variables )

Since it is a process running on a host machine

* It uses the kernel of the host machine
* And of course you need some tools to create the running container process

---

## Container Runtimes and Container Images

The Linux kernel actually has no concept of a container.

* There have been many 'container' technologies

* See [A Brief History of containers: From the 1970's till now](https://blog.aquasec.com/a-brief-history-of-containers-from-1970s-chroot-to-docker-2016)

* Over the years more capabilities have been added to the kernel to make it easier

<BR>
A 'Container technology' is:

* A Container Image Format of the unit of software deployment
    * A bundle of all the files and miscellaneous configuration 

* A Container Runtime Engine
    * Software that takes a Container Image and creates a running container

---

## The Container Runtime War is now Over

The Cloud Native Computing Foundation (CNCF) has standardized containers

* A standard container image format

* A standard for building and configuring container runtimes

* A standard REST API for loading/downloading container image to a registries 

There primary Container Runtimes are:

* containerd: using the 'docker' Command Line Interface (or Kubernetes)

* CRI-O: using the 'podman' Command Line Interface (or Kubernetes/OpenShift)

* Others exists, for example Singularity which has a history in HPC

---

## Linux Namespaces Makes Containers Possible

- Provide processes with their own isolated view of the system.

    - Namespaces limit what you can see (and therefore, what you can use).

- These namespaces are available in modern kernels:

  - pid: processes
  - net: network
  - mnt: root file system (ie chroot)
  - uts: hostname
  - ipc
  - user: UID/GID mapping
  - time: time
  - cgroup: Resource Monitoring and Limiting

- Each process belongs to one namespace of each type.

---

## Namespaces are always active

- Namespaces exist even when you don't use containers.

- This is a bit similar to the UID field in UNIX processes:

  - all processes have the UID field, even if no user exists on the system

  - the field always has a value / the value is always defined
    <br/>
    (i.e. any process running on the system has some UID)

  - the value of the UID field is used when checking permissions
    <br/>
    (the UID field determines which resources the process can access)

- You can replace "UID field" with "namespace" above and it still works!

- In other words: even when you don't use containers,
  <br/>there is one namespace of each type, containing all the processes on the system.

