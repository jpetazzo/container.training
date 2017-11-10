
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

The CNM was introduced in Engine 1.9.0 (November 2015).

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

* It can be local (to a single Engine) or global (spanning multiple hosts).

* A network has an IP subnet associated to it.

* Docker will allocate IP addresses to the containers connected to a network.

* Containers can be connected to multiple networks.

* Containers can be given per-network names and aliases.

* The names and aliases can be resolved via an embedded DNS server.

---

## Network implementation details

* A network is managed by a *driver*.

* All the drivers that we have seen before are available.

* A new multi-host driver, *overlay*, is available out of the box.

* More drivers can be provided by plugins (OVS, VLAN...)

* A network can have a custom IPAM (IP allocator).

---

## Differences with the CNI

* CNI = Container Network Interface

* CNI is used notably by Kubernetes

* With CNI, all the nodes and containers are on a single IP network

* Both CNI and CNM offer the same functionality, but with very different methods

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

## Placing containers on a network

We will create a *named* container on this network.

It will be reachable with its name, `es`.

```bash
$ docker run -d --name es --net dev elasticsearch:2
8abb80e229ce8926c7223beb69699f5f34d6f1d438bfc5682db893e798046863
```

---

## Communication between containers

Now, create another container on this network.

.small[
```bash
$ docker run -ti --net dev alpine sh
root@0ecccdfa45ef:/#
```
]

From this new container, we can resolve and ping the other one, using its assigned name:

.small[
```bash
/ # ping es
PING es (172.18.0.2) 56(84) bytes of data.
64 bytes from es.dev (172.18.0.2): icmp_seq=1 ttl=64 time=0.221 ms
64 bytes from es.dev (172.18.0.2): icmp_seq=2 ttl=64 time=0.114 ms
64 bytes from es.dev (172.18.0.2): icmp_seq=3 ttl=64 time=0.114 ms
^C
--- es ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.114/0.149/0.221/0.052 ms
root@0ecccdfa45ef:/#
```
]

---

class: extra-details

## Resolving container addresses

In Docker Engine 1.9, name resolution is implemented with `/etc/hosts`, and
updating it each time containers are added/removed.

.small[
```bash
[root@0ecccdfa45ef /]# cat /etc/hosts
172.18.0.3  0ecccdfa45ef
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.18.0.2      es
172.18.0.2      es.dev
```
]

In Docker Engine 1.10, this has been replaced by a dynamic resolver.

(This avoids race conditions when updating `/etc/hosts`.)

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

* It must have the right name (`redis`) so the application can find it.

Start the container:

```bash
$ docker run --net dev --name redis -d redis
```

---

## Test the web server again

* If we connect to the application now, we should see that the app is working correctly:

![Trainingwheels OK](images/trainingwheels-ok.png)

* When the app tries to resolve `redis`, instead of getting a DNS error, it gets the IP address of our Redis container.

---

## A few words on *scope*

* What if we want to run multiple copies of our application?

* Since names are unique, there can be only one container named `redis` at a time.

* However, we can specify the network name of our container with `--net-alias`.

* `--net-alias` is scoped per network, and independent from the container name.

---

class: extra-details

## Using a network alias instead of a name

Let's remove the `redis` container:

```bash
$ docker rm -f redis
```

And create one that doesn't block the `redis` name:

```bash
$ docker run --net dev --net-alias redis -d redis
```

Check that the app still works (but the counter is back to 1,
since we wiped out the old Redis container).

---

class: x-extra-details

## Names are *local* to each network

Let's try to ping our `es` container from another container, when that other container is *not* on the `dev` network.

```bash
$ docker run --rm alpine ping es
ping: bad address 'es'
```

Names can be resolved only when containers are on the same network.

Containers can contact each other only when they are on the same network (you can try to ping using the IP address to verify).

---

class: extra-details

## Network aliases

We would like to have another network, `prod`, with its own `es` container. But there can be only one container named `es`!

We will use *network aliases*.

A container can have multiple network aliases.

Network aliases are *local* to a given network (only exist in this network).

Multiple containers can have the same network alias (even on the same network). In Docker Engine 1.11, resolving a network alias yields the IP addresses of all containers holding this alias.

---

class: extra-details

## Creating containers on another network

Create the `prod` network.

```bash
$ docker create network prod
5a41562fecf2d8f115bedc16865f7336232a04268bdf2bd816aecca01b68d50c
```

We can now create multiple containers with the `es` alias on the new `prod` network.

```bash
$ docker run -d --name prod-es-1 --net-alias es --net prod elasticsearch:2
38079d21caf0c5533a391700d9e9e920724e89200083df73211081c8a356d771
$ docker run -d --name prod-es-2 --net-alias es --net prod elasticsearch:2
1820087a9c600f43159688050dcc164c298183e1d2e62d5694fd46b10ac3bc3d
```

---

class: extra-details

## Resolving network aliases

Let's try DNS resolution first, using the `nslookup` tool that ships with the `alpine` image.

```bash
$ docker run --net prod --rm alpine nslookup es
Name:      es
Address 1: 172.23.0.3 prod-es-2.prod
Address 2: 172.23.0.2 prod-es-1.prod
```

(You can ignore the `can't resolve '(null)'` errors.)

---

class: extra-details

## Connecting to aliased containers

Each ElasticSearch instance has a name (generated when it is started). This name can be seen when we issue a simple HTTP request on the ElasticSearch API endpoint.

Try the following command a few times:

.small[
```bash
$ docker run --rm --net dev centos curl -s es:9200
{
  "name" : "Tarot",
...
}
```
]

Then try it a few times by replacing `--net dev` with `--net prod`:

.small[
```bash
$ docker run --rm --net prod centos curl -s es:9200
{
  "name" : "The Symbiote",
...
}
```
]

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

* `--gateway` indicates which address to use for the gateway (when utbound traffic is allowed).

* `--subnet` (in CIDR notation) indicates the subnet to use.

* `--ip-range` (in CIDR notation) indicates the subnet to allocate from.

* `--aux-address` allows to specify a list of reserved addresses (which won't be allocated to containers).

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

* Docker ships with a default network plugin, `overlay`, implementing an overlay network leveraging VXLAN.

* Other plugins (Weave, Calico...) can provide overlay networks as well.

* Once you have an overlay network, *all the features that we've used in this chapter work identically.*

---

class: extra-details

## Multi-host networking (overlay)

Out of the scope for this intro-level workshop!

Very short instructions:

- enable Swarm Mode (`docker swarm init` then `docker swarm join` on other nodes)
- `docker network create mynet --driver overlay`
- `docker service create --network mynet myimage`

See http://jpetazzo.github.io/container.training for all the deets about clustering!

---

class: extra-details

## Multi-host networking (plugins)

Out of the scope for this intro-level workshop!

General idea:

- install the plugin (they often ship within containers)

- run the plugin (if it's in a container, it will often require extra parameters; don't just `docker run` it blindly!)

- some plugins require configuration or activation (creating a special file that tells Docker "use the plugin whose control socket is at the following location")

- you can then `docker network create --driver pluginname`

---

## Section summary

We've learned how to:

* Create private networks for groups of containers.

* Assign IP addresses to containers.

* Use container naming to implement service discovery.

