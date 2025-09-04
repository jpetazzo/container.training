# Exercise — Build a container from scratch

Our goal will be to execute a container running a simple web server.

(Example: NGINX, or https://github.com/jpetazzo/color.)

We want the web server to be isolated:

- it shouldn't be able to access the outside world,

- but we should be able to connect to it from our machine.

Make sure to automate / script things as much as possible!

---

## Steps

1. Prepare the filesystem

2. Run it with chroot

3. Isolation with namespaces

4. Network configuration

5. Cgroups

6. Run as non-root

7. ...But on port 80 anyways

---

## Bonus steps

In no specific order...

- Try to escape the container

  (it's OK to modify the container filesystem from outside!)

- Try to prevent container escapes by:

  - enabling user namespaces

  - dropping capabilities

  - locking down device access

---

## Prepare the filesystem

- Obtain a root filesystem with one of the following methods:

  - download an Alpine root fs

  - export an Alpine or NGINX container image with Docker

  - download and convert a container image with Skopeo

  - make it from scratch with busybox + a static [jpetazzo/color](https://github.com/jpetazzo/color)

  - ...anything you want! (Nix, anyone?)

- Enter the root filesystem with `chroot`

---

## Run with chroot

- Start the web server from within the chroot

- Confirm that you can connect to it from outside

- Write a script to start our "proto-container"

---

## Isolation with namespaces

- Now, enter the root filesystem with `unshare`

  (enable all the namespaces you want; maybe not `user` yet, though!)

- Start the web server

  (you might need to configure at least the loopback network interface!)

- Confirm that we *cannot* connect from outside

- Update the our start script to use unshare

- Automate network configuration

  (pay attention to the fact that network tools *may not* exist in the container)

---

## Network configuration

- While our "container" is running, create a `veth` pair

- Move one `veth` to the container

- Assign addresses to both `veth`

- Confirm that we can connect to the web server from outside

  (using the address assigned to the container's `veth`)

- Update our start script to automate the setup of the `veth` pair

- Bonus points: update the script to that it can start *multiple* containers

---

## Cgroups

- Create a cgroup for our container

- Move the container to the cgroup

- Set a very low CPU limit and confirm that it slows down the server

  (but doesn't affect the rest of the system)

- Update the script to automate this

---

## Non-root

- Switch to a non-privileged user when starting the container

- Adjust the web server configuration so that it starts

  (non-privileged users cannot bind to ports below 1024)

---

## Non-root, port 80

- We want to run as a non-privileged user **and** bind to port 80

- We'll need to have the correct capability to do that

- Identify the capability needed to do that

- Add that capability to the web server
