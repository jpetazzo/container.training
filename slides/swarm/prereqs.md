# Pre-requirements

- Computer with internet connection and a web browser

- For instructor-led workshops: an SSH client to connect to remote machines

  - on Linux, OS X, FreeBSD... you are probably all set

  - on Windows, get [putty](http://www.putty.org/),
  Microsoft [Win32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH),
  [Git BASH](https://git-for-windows.github.io/), or
  [MobaXterm](http://mobaxterm.mobatek.net/)

- For self-paced learning: SSH is not necessary if you use
  [Play-With-Docker](http://www.play-with-docker.com/)

- Some Docker knowledge

  (but that's OK if you're not a Docker expert!)

---

class: in-person, extra-details

## Nice-to-haves

- [Mosh](https://mosh.org/) instead of SSH, if your internet connection tends to lose packets
  <br/>(available with `(apt|yum|brew) install mosh`; then connect with `mosh user@host`)

- [GitHub](https://github.com/join) account
  <br/>(if you want to fork the repo)

- [Slack](https://community.docker.com/registrations/groups/4316) account
  <br/>(to join the conversation after the workshop)

- [Docker Hub](https://hub.docker.com) account
  <br/>(it's one way to distribute images on your cluster)

---

class: extra-details

## Extra details

- This slide should have a little magnifying glass in the top left corner

  (If it doesn't, it's because CSS is hard — Jérôme is only a backend person, alas)

- Slides with that magnifying glass indicate slides providing extra details

- Feel free to skip them if you're in a hurry!

---

## Hands-on sections

- The whole workshop is hands-on

- We will see Docker in action

- You are invited to reproduce all the demos

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!
- Go to [container.training](http://container.training/) to view these slides
- Join the chat room on @@CHAT@@

]

---

class: in-person

# VM environment

- To follow along, you need a cluster of five Docker Engines

- If you are doing this with an instructor, see next slide

- If you are doing (or re-doing) this on your own, you can:

  - create your own cluster (local or cloud VMs) with Docker Machine
    ([instructions](https://github.com/jpetazzo/orchestration-workshop/tree/master/prepare-machine))

  - use [Play-With-Docker](http://play-with-docker.com) ([instructions](https://github.com/jpetazzo/orchestration-workshop#using-play-with-docker))

  - create a bunch of clusters for you and your friends
    ([instructions](https://github.com/jpetazzo/orchestration-workshop/tree/master/prepare-vms))

---

class: pic, in-person

![You get five VMs](images/you-get-five-vms.jpg)

---

class: in-person

## You get five VMs

- Each person gets 5 private VMs (not shared with anybody else)
- They'll remain up until the day after the tutorial
- You should have a little card with login+password+IP addresses
- You can automatically SSH from one VM to another

.exercise[

<!--
```bash
for N in $(seq 1 5); do
  ssh -o StrictHostKeyChecking=no node$N true
done
```
-->

- Log into the first VM (`node1`) with SSH or MOSH
- Check that you can SSH (without password) to `node2`:
  ```bash
  ssh node2
  ```
- Type `exit` or `^D` to come back to node1

<!-- ```bash exit``` -->

]

---

## If doing or re-doing the workshop on your own ...

- Use [Play-With-Docker](http://www.play-with-docker.com/)!

- Main differences:

  - you don't need to SSH to the machines
    <br/>(just click on the node that you want to control in the left tab bar)

  - Play-With-Docker automagically detects exposed ports
    <br/>(and displays them as little badges with port numbers, above the terminal)

  - You can access HTTP services by clicking on the port numbers

  - exposing TCP services requires something like
    [ngrok](https://ngrok.com/)
    or [supergrok](https://github.com/jpetazzo/orchestration-workshop#using-play-with-docker)

<!--

- If you use VMs deployed with Docker Machine:

  - you won't have pre-authorized SSH keys to bounce across machines

  - you won't have host aliases

-->

---

class: self-paced

## Using Play-With-Docker

- Open a new browser tab to [www.play-with-docker.com](http://www.play-with-docker.com/)

- Confirm that you're not a robot

- Click on "ADD NEW INSTANCE": congratulations, you have your first Docker node!

- When you will need more nodes, just click on "ADD NEW INSTANCE" again

- Note the countdown in the corner; when it expires, your instances are destroyed

- If you give your URL to somebody else, they can access your nodes too
  <br/>
  (You can use that for pair programming, or to get help from a mentor)

- Loving it? Not loving it? Tell it to the wonderful authors,
  [@marcosnils](https://twitter.com/marcosnils) &
  [@xetorthio](https://twitter.com/xetorthio)!

---

## We will (mostly) interact with node1 only

- Unless instructed, **all commands must be run from the first VM, `node1`**

- We will only checkout/copy the code on `node1`

- When we will use the other nodes, we will do it mostly through the Docker API

- We will log into other nodes only for initial setup and a few "out of band" operations
  <br/>(checking internal logs, debugging...)

---

## Terminals

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.

---

## Tmux cheatsheet

- Ctrl-b c → creates a new window
- Ctrl-b n → go to next window
- Ctrl-b p → go to previous window
- Ctrl-b " → split window top/bottom
- Ctrl-b % → split window left/right
- Ctrl-b Alt-1 → rearrange windows in columns
- Ctrl-b Alt-2 → rearrange windows in rows
- Ctrl-b arrows → navigate to other windows
- Ctrl-b d → detach session
- tmux attach → reattach to session
