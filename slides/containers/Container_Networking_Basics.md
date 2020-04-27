
class: title

# Container networking basics

![A dense graph network](images/title-container-networking-basics.jpg)

---

## Objectives

We will now run network services (accepting requests) in containers.

At the end of this section, you will be able to:

* Run a network service in a container.

* Manipulate container networking basics.

* Find a container's IP address.

We will also explain the different network models used by Docker.

---

## A simple, static web server

Run the Docker Hub image `nginx`, which contains a basic web server:

```bash
$ docker run -d -P nginx
66b1ce719198711292c8f34f84a7b68c3876cf9f67015e752b94e189d35a204e
```

* Docker will download the image from the Docker Hub.

* `-d` tells Docker to run the image in the background.

* `-P` tells Docker to make this service reachable from other computers.
  <br/>(`-P` is the short version of `--publish-all`.)

But, how do we connect to our web server now?

---

## Finding our web server port

We will use `docker ps`:

```bash
$ docker ps
CONTAINER ID  IMAGE  ...  PORTS                  ...
e40ffb406c9e  nginx  ...  0.0.0.0:32768->80/tcp  ...
```


* The web server is running on port 80 inside the container.

* This port is mapped to port 32768 on our Docker host.

We will explain the whys and hows of this port mapping.

But first, let's make sure that everything works properly.

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
$ curl localhost:32768
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

## Why are we mapping ports?

* We are out of IPv4 addresses.

* Containers cannot have public IPv4 addresses.

* They have private addresses.

* Services have to be exposed port by port.

* Ports have to be mapped to avoid conflicts.

---

## Finding the web server port in a script

Parsing the output of `docker ps` would be painful.

There is a command to help us:

```bash
$ docker port <containerID> 80
32768
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

* Use a network plugin, connecting your containers with e.g. VLANs, tunnels...

* Enable *Swarm Mode* to deploy across a cluster.
  <br/>The container will then be reachable through any node of the cluster.

When using Docker through an extra management layer like Mesos or Kubernetes,
these will usually provide their own mechanism to expose containers.

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

We can test connectivity to the container using the IP address we've
just discovered. Let's see this now by using the `ping` tool.

```bash
$ ping <ipAddress>
64 bytes from <ipAddress>: icmp_req=1 ttl=64 time=0.085 ms
64 bytes from <ipAddress>: icmp_req=2 ttl=64 time=0.085 ms
64 bytes from <ipAddress>: icmp_req=3 ttl=64 time=0.085 ms
```

---

## Section summary

We've learned how to:

* Expose a network port.

* Manipulate container networking basics.

* Find a container's IP address.

In the next chapter, we will see how to connect
containers together without exposing their ports.

???

:EN:Connecting containers
:EN:- Container networking basics
:EN:- Exposing a container

:FR:Connecter les conteneurs
:FR:- Description du modèle réseau des conteneurs
:FR:- Exposer un conteneur
