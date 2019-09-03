# Pre-requirements

- Be comfortable with the UNIX command line

  - navigating directories

  - editing files

  - a little bit of bash-fu (environment variables, loops)

- Some Docker knowledge

  - `docker run`, `docker ps`, `docker build`

  - ideally, you know how to write a Dockerfile and build it
    <br/>
    (even if it's a `FROM` line and a couple of `RUN` commands)

- It's totally OK if you are not a Docker expert!

---

## software pre-requirements

- You'll need the following software installed on your local laptop:

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/docs/using_helm/#installing-helm)

- Bonus tools

* [octant](https://github.com/vmware/octant#installation)
* [stern](https://github.com/wercker/stern/releases/tag/1.11.0)
* [jq](https://stedolan.github.io/jq/download/)

---

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

- The whole workshop is hands-on

- You are invited to reproduce all the demos

- You will be using conference wifi and a shared kubernetes cluster. Please be kind to both.

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!

- Go to @@SLIDES@@ to view these slides

- Join the chat room: @@CHAT@@

<!-- ```open @@SLIDES@@``` -->

]

---

class: in-person

## Where are we going to run our containers?

---

class: in-person

## shared cluster dedicated to this workshop

- A large Pivotal Container Service (PKS) cluster deployed to Google Cloud.

- It remain up for the duration of the workshop

- You should have a little card with login+password+URL

- Logging into this URL will give you a downloadable kubeconfig file.

---

class: in-person

## Why don't we run containers locally?

- Installing this stuff can be hard on some machines

  (32 bits CPU or OS... Laptops without administrator access... etc.)

- *"The whole team downloaded all these container images from the WiFi!
  <br/>... and it went great!"* (Literally no-one ever)

- All you need is a computer (or even a phone or tablet!), with:

  - an internet connection

  - a web browser

  - kubectl

  - helm
