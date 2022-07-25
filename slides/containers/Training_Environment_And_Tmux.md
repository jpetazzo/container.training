
class: title

# Our training environment

![SSH terminal](images/title-our-training-environment.jpg)


---

class: in-person

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

class: in-person

## Connecting to our lab environment

.lab[

- Log into your VM with your SSH client:
  ```bash
  ssh `user`@`A.B.C.D`
  ```

  (Replace `user` and `A.B.C.D` with the user and IP address provided to you)


]

You should see a prompt looking like this:
```
[A.B.C.D] (...) user@node1 ~
$
```
If anything goes wrong — ask for help!

---
## Our Docker VM

About the Lab VM

- The VM is created just before the training.

- It will stay up during the whole training.

- It will be destroyed shortly after the training.

- It comes pre-loaded with Docker and some other useful tools.

---

## Why don't we run Docker locally?

- I can log into your VMs to help you with labs

- Installing docker is out of the scope of this class (lots of online docs)

    - It's better to spend time learning containers than fiddling with the installer!

---
class: in-person

## `tailhist`

- The shell history of the instructor is available online in real time

- Note the IP address of the instructor's virtual machine (A.B.C.D)

- Open http://A.B.C.D:1088 in your browser and you should see the history

- The history is updated in real time  (using a WebSocket connection)

- It should be green when the WebSocket is connected

  (if it turns red, reloading the page should fix it)

- If you want to play with it on your lab machine, tailhist is installed

    - sudo apt install firewalld
    - sudo firewall-cmd --add-port=1088/tcp
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


---

## Doing or re-doing the workshop on your own?

- Use something like
  [Play-With-Docker](http://play-with-docker.com/) or
  [Play-With-Kubernetes](https://training.play-with-kubernetes.com/)

  Zero setup effort; but environment are short-lived and
  might have limited resources

- Create your own cluster (local or cloud VMs)

  Small setup effort; small cost; flexible environments

- Create a bunch of clusters for you and your friends
    ([instructions](https://@@GITREPO@@/tree/master/prepare-vms))

  Bigger setup effort; ideal for group training

---

class: self-paced

## Get your own Docker nodes

- If you already have some Docker nodes: great!

- If not: let's get some thanks to Play-With-Docker

.lab[

- Go to http://www.play-with-docker.com/

- Log in

- Create your first node

<!-- ```open http://www.play-with-docker.com/``` -->

]

You will need a Docker ID to use Play-With-Docker.

(Creating a Docker ID is free.)

---

## Terminals

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.

---

## Tmux cheat sheet

[Tmux](https://en.wikipedia.org/wiki/Tmux) is a terminal multiplexer like `screen`.

*You don't have to use it or even know about it to follow along.
<br/>
But some of us like to use it to switch between terminals.
<br/>
It has been preinstalled on your workshop nodes.*

- Ctrl-b c → creates a new window
- Ctrl-b n → go to next window
- Ctrl-b p → go to previous window
- Ctrl-b " → split window top/bottom
- Ctrl-b % → split window left/right
- Ctrl-b Alt-1 → rearrange windows in columns
- Ctrl-b Alt-2 → rearrange windows in rows
- Ctrl-b arrows → navigate to other windows
- Ctrl-b d → detach session
- tmux attach → re-attach to session
