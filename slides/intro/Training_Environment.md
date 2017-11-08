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

  - use http://www.play-with-docker.com/ to instantly get a training environment

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

## Connecting to your Virtual Machine

You need an SSH client.

* On OS X, Linux, and other UNIX systems, just use `ssh`:

```bash
$ ssh <login>@<ip-address>
```

* On Windows, if you don't have an SSH client, you can download:

  * Putty (www.putty.org)

  * Git BASH (https://git-for-windows.github.io/)

  * MobaXterm (http://moabaxterm.mobatek.net)

---

## Checking your Virtual Machine

Once logged in, make sure that you can run a basic Docker command:

.small[
```bash
$ docker version
Client:
 Version:      17.09.0-ce
 API version:  1.32
 Go version:   go1.8.3
 Git commit:   afdb6d4
 Built:        Tue Sep 26 22:40:09 2017
 OS/Arch:      darwin/amd64

Server:
 Version:      17.09.0-ce
 API version:  1.32 (minimum version 1.12)
 Go version:   go1.8.3
 Git commit:   afdb6d4
 Built:        Tue Sep 26 22:45:38 2017
 OS/Arch:      linux/amd64
 Experimental: true
```
]

If this doesn't work, raise your hand so that an instructor can assist you!
