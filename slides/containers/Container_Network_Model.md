
class: title

# The Container Network Model

![A denser graph network](images/title-the-container-network-model.jpg)

---

## Objectives

We will learn about the CNM (Container Network Model).

At the end of this lesson, you will be able to:

* Create a private network for a group of containers.

* Use container naming to connect services together.

* Dynamically connect and disconnect containers to networks.

* Set the IP address of a container.

We will also explain the principle of overlay networks and network plugins.

---

## The Container Network Model

The CNM adds the notion of a *network*, and a new top-level command to manipulate and see those networks: `docker network`.

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER
6bde79dfcf70        bridge              bridge
8d9c78725538        none                null
eb0eeab782f4        host                host
4c1ff84d6d3f        blog-dev            overlay
228a4355d548        blog-prod           overlay
```

---

## What's in a network?

* Conceptually, a network is a virtual switch.

  (It's similar to e.g. a VLAN, or a WiFi network.)

* It can be local (to a single Engine) or global (spanning multiple hosts).

* A network has an IP subnet associated to it.

* Docker will allocate IP addresses to the containers connected to a network.

* Containers can be connected to multiple networks.

* Containers can be given per-network names and aliases.

* The names and aliases can be resolved via an embedded DNS server.

---

## Network implementation details

* A network is managed by a *driver*.

* The built-in drivers include:

  * `bridge` (default)

  * `none`

  * `host`

  * `macvlan`

* A multi-host driver, *overlay*, is available out of the box (for Swarm clusters).

* More drivers can be provided by plugins (OVS, VLAN...)

* A network can have a custom IPAM (IP allocator).

---

class: extra-details

## Differences with the CNI

* CNI = Container Network Interface

* CNI is used notably by Kubernetes

* With CNI, all the nodes and containers are on a single IP network

* Both CNI and CNM offer the same functionality, but with very different methods

---

class: pic

## Single container in a Docker network

![bridge0](images/bridge1.png)

---

class: pic

## Two containers on a single Docker network

![bridge2](images/bridge2.png)

---

class: pic

## Two containers on two Docker networks

![bridge3](images/bridge3.png)

---

## Creating a network

Let's create a network called `dev`.

```bash
$ docker network create dev
4c1ff84d6d3f1733d3e233ee039cac276f425a9d5228a4355d54878293a889ba
```

The network is now visible with the `network ls` command:

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER
6bde79dfcf70        bridge              bridge
8d9c78725538        none                null
eb0eeab782f4        host                host
4c1ff84d6d3f        dev                 bridge
```

---

# Service discovery with containers

* Let's try to run an application that requires two containers.

* The first container is a web server.

* The other one is a redis data store.

* We will place them both on the `dev` network created before.

---

## Running the web server

* The application is provided by the container image `jpetazzo/trainingwheels`.

* We don't know much about it so we will try to run it and see what happens!

Start the container, exposing all its ports:

```bash
$ docker run --net dev -d -P jpetazzo/trainingwheels
```

Check the port that has been allocated to it:

```bash
$ docker ps -l
```

---

## Test the web server

* If we connect to the application now, we will see an error page:

![Trainingwheels error](images/trainingwheels-error.png)

* This is because the Redis service is not running.
* This container tries to resolve the name `redis`.

Note: we're not using a FQDN or an IP address here; just `redis`.

---

## Start the data store

* We need to start a Redis container.

* That container must be on the same network as the web server.

* We must give it a network alias (`redis`) so the application can find it.

Start the container:

```bash
$ docker run --net dev --net-alias redis -d redis
```

Note: we could also use `--name redis`.

---

## Test the web server again

* If we connect to the application now, we should see that the app is working correctly:

![Trainingwheels OK](images/trainingwheels-ok.png)

* When the app tries to resolve `redis`, instead of getting a DNS error, it gets the IP address of our Redis container.

---

## A few words on *scope*

* What if we want to run multiple copies of our application?

* We can use `--net-alias redis` for multiple containers.

* Network aliases are scoped per network, and independent from container names.

* However, we can use `--name redis` only once, since names are unique.

---

## Good to know ...

* Docker will not create network names and aliases on the default `bridge` network.

* Therefore, if you want to use those features, you have to create a custom network first.

* Network aliases are *not* unique on a given network.

* i.e., multiple containers can have the same alias on the same network.

* In that scenario, the Docker DNS server will return multiple records.
  <br/>
  (i.e. you will get DNS round robin out of the box.)

* Enabling *Swarm Mode* gives access to clustering and load balancing with IPVS.

* Creation of networks and network aliases is generally automated with tools like Compose.

---

class: extra-details

## A few words about round robin DNS

Don't rely exclusively on round robin DNS to achieve load balancing.

Many factors can affect DNS resolution, and you might see:

- all traffic going to a single instance;
- traffic being split (unevenly) between some instances;
- different behavior depending on your application language;
- different behavior depending on your base distro;
- different behavior depending on other factors (sic).

It's OK to use DNS to discover available endpoints, but remember that you have to re-resolve every now and then to discover new endpoints.

---

class: extra-details

## Custom networks

When creating a network, extra options can be provided.

* `--internal` disables outbound traffic (the network won't have a default gateway).

* `--gateway` indicates which address to use for the gateway (when outbound traffic is allowed).

* `--subnet` (in CIDR notation) indicates the subnet to use.

* `--ip-range` (in CIDR notation) indicates the subnet to allocate from.

* `--aux-address` allows specifying a list of reserved addresses (which won't be allocated to containers).

---

class: extra-details

## Setting containers' IP address

* It is possible to set a container's address with `--ip`.
* The IP address has to be within the subnet used for the container.

A full example would look like this.

```bash
$ docker network create --subnet 10.66.0.0/16 pubnet
42fb16ec412383db6289a3e39c3c0224f395d7f85bcb1859b279e7a564d4e135
$ docker run --net pubnet --ip 10.66.66.66 -d nginx
b2887adeb5578a01fd9c55c435cad56bbbe802350711d2743691f95743680b09
```

*Note: don't hard code container IP addresses in your code!*

*I repeat: don't hard code container IP addresses in your code!*

---

## Overlay networks

* The features we've seen so far only work when all containers are on a single host.

* If containers span multiple hosts, we need an *overlay* network to connect them together.

* Docker ships with a default network plugin, `overlay`, implementing an overlay network leveraging
  VXLAN, *enabled with Swarm Mode*.

* Other plugins (Weave, Calico...) can provide overlay networks as well.

* Once you have an overlay network, *all the features that we've used in this chapter work identically
  across multiple hosts.*

---

class: extra-details

## Multi-host networking (overlay)

Out of the scope for this intro-level workshop!

Very short instructions:

- enable Swarm Mode (`docker swarm init` then `docker swarm join` on other nodes)
- `docker network create mynet --driver overlay`
- `docker service create --network mynet myimage`

If you want to learn more about Swarm mode, you can check
[this video](https://www.youtube.com/watch?v=EuzoEaE6Cqs)
or [these slides](https://container.training/swarm-selfpaced.yml.html).

---

class: extra-details

## Multi-host networking (plugins)

Out of the scope for this intro-level workshop!

General idea:

- install the plugin (they often ship within containers)

- run the plugin (if it's in a container, it will often require extra parameters; don't just `docker run` it blindly!)

- some plugins require configuration or activation (creating a special file that tells Docker "use the plugin whose control socket is at the following location")

- you can then `docker network create --driver pluginname`
