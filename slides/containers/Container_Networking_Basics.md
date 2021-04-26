
class: title

# Container networking basics

![A dense graph network](images/title-container-networking-basics.jpg)

---

## Objectives

We will now run network services (accepting requests) in containers.

At the end of this section, you will be able to:

* Run a network service in a container.

* Connect to that network service.

* Find a container's IP address.

---

## Running a very simple service

- We need something small, simple, easy to configure

  (or, even better, that doesn't require any configuration at all)

- Let's use the official NGINX image (named `nginx`)

- It runs a static web server listening on port 80

- It serves a default "Welcome to nginx!" page

---

## Runing an NGINX server

```bash
$ docker run -d -P nginx
66b1ce719198711292c8f34f84a7b68c3876cf9f67015e752b94e189d35a204e
```

- Docker will automatically pull the `nginx` image from the Docker Hub

- `-d` / `--detach` tells Docker to run it in the background

- `P` / `--publish-all` tells Docker to publish all ports

  (publish = make them reachable from other computers)

- ...OK, how do we connect to our web server now?

---

## Finding our web server port

- First, we need to find the *port number* used by Docker

  (the NGINX container listens on port 80, but this port will be *mapped*)

- We can use `docker ps`:
  ```bash
  $ docker ps
  CONTAINER ID  IMAGE  ...  PORTS                  ...
  e40ffb406c9e  nginx  ...  0.0.0.0:`12345`->80/tcp  ...
  ```

- This means:

  *port 12345 on the Docker host is mapped to port 80 in the container*

- Now we need to connect to the Docker host!

---

## Finding the address of the Docker host

- When running Docker on your Linux workstation:

  *use `localhost`, or any IP address of your machine*

- When running Docker on a remote Linux server:

  *use any IP address of the remote machine*

- When running Docker Desktop on Mac or Windows:

  *use `localhost`*

- In other scenarios (`docker-machine`, local VM...):

  *use the IP address of the Docker VM*
  
---

## Connecting to our web server (GUI)

Point your browser to the IP address of your Docker host, on the port
shown by `docker ps` for container port 80.

![Screenshot](images/welcome-to-nginx.png)

---

## Connecting to our web server (CLI)

You can also use `curl` directly from the Docker host.

Make sure to use the right port number if it is different
from the example below:

```bash
$ curl localhost:12345
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

---

## How does Docker know which port to map?

* There is metadata in the image telling "this image has something on port 80".

* We can see that metadata with `docker inspect`:

```bash
$ docker inspect --format '{{.Config.ExposedPorts}}' nginx
map[80/tcp:{}]
```

* This metadata was set in the Dockerfile, with the `EXPOSE` keyword.

* We can see that with `docker history`:

```bash
$ docker history nginx
IMAGE               CREATED             CREATED BY
7f70b30f2cc6        11 days ago         /bin/sh -c #(nop)  CMD ["nginx" "-g" "…
<missing>           11 days ago         /bin/sh -c #(nop)  STOPSIGNAL [SIGTERM]
<missing>           11 days ago         /bin/sh -c #(nop)  EXPOSE 80/tcp
```

---

## Why can't we just connect to port 80?

- Our Docker host has only one port 80

- Therefore, we can only have one container at a time on port 80

- Therefore, if multiple containers want port 80, only one can get it

- By default, containers *do not* get "their" port number, but a random one

  (not "random" as "crypto random", but as "it depends on various factors")

- We'll see later how to force a port number (including port 80!)

---

class: extra-details

## Using multiple IP addresses

*Hey, my network-fu is strong, and I have questions...*

- Can I publish one container on 127.0.0.2:80, and another on 127.0.0.3:80?

- My machine has multiple (public) IP addresses, let's say A.A.A.A and B.B.B.B.
  <br/>
  Can I have one container on A.A.A.A:80 and another on B.B.B.B:80?

- I have a whole IPV4 subnet, can I allocate it to my containers?

- What about IPV6?

You can do all these things when running Docker directly on Linux.

(On other platforms, *generally not*, but there are some exceptions.)

---

## Finding the web server port in a script

Parsing the output of `docker ps` would be painful.

There is a command to help us:

```bash
$ docker port <containerID> 80
0.0.0.0:12345
```

---

## Manual allocation of port numbers

If you want to set port numbers yourself, no problem:

```bash
$ docker run -d -p 80:80 nginx
$ docker run -d -p 8000:80 nginx
$ docker run -d -p 8080:80 -p 8888:80 nginx
```

* We are running three NGINX web servers.
* The first one is exposed on port 80.
* The second one is exposed on port 8000.
* The third one is exposed on ports 8080 and 8888.

Note: the convention is `port-on-host:port-on-container`.

---

## Plumbing containers into your infrastructure

There are many ways to integrate containers in your network.

* Start the container, letting Docker allocate a public port for it.
  <br/>Then retrieve that port number and feed it to your configuration.

* Pick a fixed port number in advance, when you generate your configuration.
  <br/>Then start your container by setting the port numbers manually.

* Use an orchestrator like Kubernetes or Swarm.
  <br/>The orchestrator will provide its own networking facilities.

Orchestrators typically provide mechanisms to enable direct container-to-container
communication across hosts, and publishing/load balancing for inbound traffic.

---

## Finding the container's IP address

We can use the `docker inspect` command to find the IP address of the
container.

```bash
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' <yourContainerID>
172.17.0.3
```

* `docker inspect` is an advanced command, that can retrieve a ton
  of information about our containers.

* Here, we provide it with a format string to extract exactly the
  private IP address of the container.

---

## Pinging our container

Let's try to ping our container *from another container.*

```bash
docker run alpine ping `<ipaddress>`
PING 172.17.0.X (172.17.0.X): 56 data bytes
64 bytes from 172.17.0.X: seq=0 ttl=64 time=0.106 ms
64 bytes from 172.17.0.X: seq=1 ttl=64 time=0.250 ms
64 bytes from 172.17.0.X: seq=2 ttl=64 time=0.188 ms
```

When running on Linux, we can even ping that IP address directly!

(And connect to a container's ports even if they aren't published.)

---

## How often do we use `-p` and `-P` ?

- When running a stack of containers, we will often use Compose

- Compose will take care of exposing containers

  (through a `ports:` section in the `docker-compose.yml` file)

- It is, however, fairly common to use `docker run -P` for a quick test

- Or `docker run -p ...` when an image doesn't `EXPOSE` a port correctly

---

## Section summary

We've learned how to:

* Expose a network port.

* Connect to an application running in a container.

* Find a container's IP address.

???

:EN:- Exposing single containers
:FR:- Exposer un conteneur isolé
