
class: title

# Our first containers

![Colorful plastic tubs](images/title-our-first-containers.jpg)

---

## Objectives

At the end of this lesson, you will have:

* Seen Docker in action.

* Started your first containers.

---

## Hello World

In your Docker environment, just run the following command:

```bash
$ docker run busybox echo hello world
hello world
```

(If your Docker install is brand new, you will also see a few extra lines,
corresponding to the download of the `busybox` image.)

---

## That was our first container!

* We used one of the smallest, simplest images available: `busybox`.

* `busybox` is typically used in embedded systems (phones, routers...)

* We ran a single process and echo'ed `hello world`.

---

## A more useful container

Let's run a more exciting container:

```bash
$ docker run -it ubuntu
root@04c0bb0a6c07:/#
```

* This is a brand new container.

* It runs a bare-bones, no-frills `ubuntu` system.

* `-it` is shorthand for `-i -t`.

  * `-i` tells Docker to connect us to the container's stdin.

  * `-t` tells Docker that we want a pseudo-terminal.

---

## Do something in our container

Try to run `figlet` in our container.

```bash
root@04c0bb0a6c07:/# figlet hello
bash: figlet: command not found
```

Alright, we need to install it.

---

## Install a package in our container

We want `figlet`, so let's install it:

```bash
root@04c0bb0a6c07:/# apt-get update
...
Fetched 1514 kB in 14s (103 kB/s)
Reading package lists... Done
root@04c0bb0a6c07:/# apt-get install figlet
Reading package lists... Done
...
```

One minute later, `figlet` is installed!

---

## Try to run our freshly installed program

The `figlet` program takes a message as parameter.

```bash
root@04c0bb0a6c07:/# figlet hello
 _          _ _       
| |__   ___| | | ___  
| '_ \ / _ \ | |/ _ \ 
| | | |  __/ | | (_) |
|_| |_|\___|_|_|\___/ 
```

Beautiful! 😍

---

class: in-person

## Counting packages in the container

Let's check how many packages are installed there.

```bash
root@04c0bb0a6c07:/# dpkg -l | wc -l
97
```

* `dpkg -l` lists the packages installed in our container

* `wc -l` counts them

How many packages do we have on our host?

---

class: in-person

## Counting packages on the host

Exit the container by logging out of the shell, like you would usually do.

(E.g. with `^D` or `exit`)

```bash
root@04c0bb0a6c07:/# exit
```

Now, try to:

* run `dpkg -l | wc -l`. How many packages are installed?

* run `figlet`. Does that work?

---

class: self-paced

## Comparing the container and the host

Exit the container by logging out of the shell, with `^D` or `exit`.

Now try to run `figlet`. Does that work?

(It shouldn't; except if, by coincidence, you are running on a machine where figlet was installed before.)

---

## Host and containers are independent things

* We ran an `ubuntu` container on an Linux/Windows/macOS host.

* They have different, independent packages.

* Installing something on the host doesn't expose it to the container.

* And vice-versa.

* Even if both the host and the container have the same Linux distro!

* We can run *any container* on *any host*.

  (One exception: Windows containers can only run on Windows hosts; at least for now.)

---

## Where's our container?

* Our container is now in a *stopped* state.

* It still exists on disk, but all compute resources have been freed up.

* We will see later how to get back to that container.

---

## Starting another container

What if we start a new container, and try to run `figlet` again?
 
```bash
$ docker run -it ubuntu
root@b13c164401fb:/# figlet
bash: figlet: command not found
```

* We started a *brand new container*.

* The basic Ubuntu image was used, and `figlet` is not here.

---

## Where's my container?

* Can we reuse that container that we took time to customize?

  *We can, but that's not the default workflow with Docker.*

* What's the default workflow, then?

  *Always start with a fresh container.*
  <br/>
  *If we need something installed in our container, build a custom image.*

* That seems complicated!

  *We'll see that it's actually pretty easy!*

* And what's the point?

  *This puts a strong emphasis on automation and repeatability. Let's see why ...*

---

## Pets vs. Cattle

* In the "pets vs. cattle" metaphor, there are two kinds of servers.

* Pets:

  * have distinctive names and unique configurations

  * when they have an outage, we do everything we can to fix them

* Cattle:

  * have generic names (e.g. with numbers) and generic configuration

  * configuration is enforced by configuration management, golden images ...

  * when they have an outage, we can replace them immediately with a new server

* What's the connection with Docker and containers?

---

## Local development environments

* When we use local VMs (with e.g. VirtualBox or VMware), our workflow looks like this:

  * create VM from base template (Ubuntu, CentOS...)

  * install packages, set up environment

  * work on project

  * when done, shut down VM

  * next time we need to work on project, restart VM as we left it

  * if we need to tweak the environment, we do it live

* Over time, the VM configuration evolves, diverges.

* We don't have a clean, reliable, deterministic way to provision that environment.

---

## Local development with Docker

* With Docker, the workflow looks like this:

  * create container image with our dev environment

  * run container with that image

  * work on project

  * when done, shut down container

  * next time we need to work on project, start a new container

  * if we need to tweak the environment, we create a new image

* We have a clear definition of our environment, and can share it reliably with others.

* Let's see in the next chapters how to bake a custom image with `figlet`!

???

:EN:- Running our first container
:FR:- Lancer nos premiers conteneurs
