
class: title

# Our training environment

![SSH terminal](images/title-our-training-environment.jpg)

---

## Installing Docker

- For the hands on parts, we'll need Docker installed

- On Mac or Windows: the easiest solution is Docker Desktop

  (it's free; with upsells for extra features)

- On Linux: the easiest solution is Docker CE

  (Community Edition; a set of open source packages)

---

## What *is* Docker?

- "Installing Docker" really means "Installing the Docker Engine and CLI".

- The Docker Engine is a daemon (a service running in the background).

- This daemon manages containers, the same way that a hypervisor manages VMs.

- We interact with the Docker Engine by using the Docker CLI.

- The Docker CLI and the Docker Engine communicate through an API.

- There are many other programs and client libraries which use that API.

---

class: in-person

## `tailhist`

The shell history of the instructor is available online in real time.

Note the IP address of the instructor's virtual machine (A.B.C.D).

Open http://A.B.C.D:1088 in your browser and you should see the history.

The history is updated in real time (using a WebSocket connection).

It should be green when the WebSocket is connected.

If it turns red, reloading the page should fix it.

---

## Checking our Docker install

Let's make sure that we can run a basic Docker command:

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

???

:EN:Container concepts
:FR:Premier contact avec les conteneurs

:EN:- What's a container engine?
:FR:- Qu'est-ce qu'un *container engine* ?
