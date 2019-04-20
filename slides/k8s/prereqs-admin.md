# Pre-requirements

- Kubernetes concepts

  (pods, deployments, services, labels, selectors)

- Hands-on experience working with containers

  (building images, running them; doesn't matter how exactly)

- Familiar with the UNIX command-line

  (navigating directories, editing files, using `kubectl`)

---

## Labs and exercises

- We are going to build and break multiple clusters

- Everyone will get their own private environment(s)

- You are invited to reproduce all the demos (but you don't have to)

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!

- Go to @@SLIDES@@ to view these slides

- Join the chat room: @@CHAT@@

<!-- ```open @@SLIDES@@``` -->

]

---

## Private environments

- Each person gets their own private set of VMs

- Each person should have a printed card with connection information

- We will connect to these VMs with SSH

  (if you don't have an SSH client, install one **now!**)

---

## Doing or re-doing this on your own?

- We are using basic cloud VMs with Ubuntu LTS

- The Kubernetes packages have been installed

  (from official repos)

- We disabled IP address checks

  (to allow pod IP addresses to be carried by the cloud network)
