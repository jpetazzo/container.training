class: title

*Tell me and I forget.*
<br/>
*Teach me and I remember.*
<br/>
*Involve me and I learn.*

Misattributed to Benjamin Franklin

[(Probably inspired by Chinese Confucian philosopher Xunzi)](https://www.barrypopik.com/index.php/new_york_city/entry/tell_me_and_i_forget_teach_me_and_i_may_remember_involve_me_and_i_will_lear/)

---

## Hands-on sections

- There will be *a lot* of examples and demos

- We are going to build, ship, and run containers (and sometimes, clusters!)

- If you want, you can run all the examples and demos in your environment

  (but you don't have to; it's up to you!)

- All hands-on sections are clearly identified, like the gray rectangle below

.lab[

- This is a command that we're gonna run:
  ```bash
  echo hello world
  ```

]

---

class: in-person

## Where are we going to run our containers?

---

class: in-person, pic

![You get a cluster](images/you-get-a-cluster.jpg)

---

## If you're attending a live training or workshop

- Each person gets a private lab environment

  (depending on the scenario, this will be one VM, one cluster, multiple clusters...)

- The instructor will tell you how to connect to your environment

- Your lab environments will be available for the duration of the workshop

  (check with your instructor to know exactly when they'll be shutdown)

---

## Running your own lab environments

- If you are following a self-paced course...

- Or watching a replay of a recorded course...

- ...You will need to set up a local environment for the labs

- If you want to deliver your own training or workshop:

  - deployment scripts are available in the [prepare-labs] directory

  - you can use them to automatically deploy many lab environments

  - they support many different infrastructure providers

[prepare-labs]: https://github.com/jpetazzo/container.training/tree/main/prepare-labs

---

class: in-person

## Why don't we run containers locally?

- Installing this stuff can be hard on some machines

  (32 bits CPU or OS... Laptops without administrator access... etc.)

- *"The whole team downloaded all these container images from the WiFi!
  <br/>... and it went great!"* (Literally no-one ever)

- All you need is a computer (or even a phone or tablet!), with:

  - an Internet connection

  - a web browser

  - an SSH client

---

class: in-person

## SSH clients

- On Linux, OS X, FreeBSD... you are probably all set

- On Windows, get one of these:

  - [putty](https://putty.software/)
  - Microsoft [Win32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH)
  - [Git BASH](https://git-for-windows.github.io/)
  - [MobaXterm](http://mobaxterm.mobatek.net/)

- On Android, [JuiceSSH](https://juicessh.com/)
  ([Play Store](https://play.google.com/store/apps/details?id=com.sonelli.juicessh))
  works pretty well

- Nice-to-have: [Mosh](https://mosh.org/) instead of SSH, if your Internet connection tends to lose packets

---

class: in-person, extra-details

## What is this Mosh thing?

*You don't have to use Mosh or even know about it to follow along.
<br/>
We're just telling you about it because some of us think it's cool!*

- Mosh is "the mobile shell"

- It is essentially SSH over UDP, with roaming features

- It retransmits packets quickly, so it works great even on lossy connections

  (Like hotel or conference WiFi)

- It has intelligent local echo, so it works great even in high-latency connections

  (Like hotel or conference WiFi)

- It supports transparent roaming when your client IP address changes

  (Like when you hop from hotel to conference WiFi)

---

class: in-person, extra-details

## Using Mosh

- To install it: `(apt|yum|brew) install mosh`

- It has been pre-installed on the VMs that we are using

- To connect to a remote machine: `mosh user@host`

  (It is going to establish an SSH connection, then hand off to UDP)

- It requires UDP ports to be open

  (By default, it uses a UDP port between 60000 and 61000)
