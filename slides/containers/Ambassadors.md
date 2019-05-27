
class: title

# Ambassadors

![Two serious-looking persons shaking hands](images/title-ambassador.jpg)

---

## The ambassador pattern

Ambassadors are containers that "masquerade" or "proxy" for another service.

They abstract the connection details for this services, and can help with:

* discovery (where is my service actually running?)

* migration (what if my service has to be moved while I use it?)

* fail over (how do I know to which instance of a replicated service I should connect?)

* load balancing (how to I spread my requests across multiple instances of a service?)

* authentication (what if my service requires credentials, certificates, or otherwise?)

---

## Introduction to Ambassadors

The ambassador pattern:

* Takes advantage of Docker's per-container naming system and abstracts
  connections between services.

* Allows you to manage services without hard-coding connection
  information inside applications.

To do this, instead of directly connecting containers you insert
ambassador containers.

---

class: pic

![ambassador](images/ambassador-diagram.png)

---

## Interacting with ambassadors

* The web container uses normal Docker networking to connect
  to the ambassador.

* The database container also talks with an ambassador.

* For both containers, the ambassador is totally transparent.
  <br/>
  (There is no difference between normal
  operation and operation with an ambassador.)

* If the database container is moved (or a failover happens), its new location will
  be tracked by the ambassador containers, and the web application
  container will still be able to connect, without reconfiguration.

---

## Ambassadors for simple service discovery

Use case:

* my application code connects to `redis` on the default port (6379),
* my Redis service runs on another machine, on a non-default port (e.g. 12345),
* I want to use an ambassador to let my application connect without modification.

The ambassador will be:

* a container running right next to my application,
* using the name `redis` (or linked as `redis`),
* listening on port 6379,
* forwarding connections to the actual Redis service.

---

## Ambassadors for service migration

Use case:

* my application code still connects to `redis`,
* my Redis service runs somewhere else,
* my Redis service is moved to a different host+port,
* the location of the Redis service is given to me via e.g. DNS SRV records,
* I want to use an ambassador to automatically connect to the new location, with as little disruption as possible.

The ambassador will be:

* the same kind of container as before,
* running an additional routine to monitor DNS SRV records,
* updating the forwarding destination when the DNS SRV records are updated.

---

## Ambassadors for credentials injection

Use case:

* my application code still connects to `redis`,
* my application code doesn't provide Redis credentials,
* my production Redis service requires credentials,
* my staging Redis service requires different credentials,
* I want to use an ambassador to abstract those credentials.

The ambassador will be:

* a container using the name `redis` (or a link),
* passed the credentials to use,
* running a custom proxy that accepts connections on Redis default port,
* performing authentication with the target Redis service before forwarding traffic.

---

## Ambassadors for load balancing

Use case:

* my application code connects to a web service called `api`,
* I want to run multiple instances of the `api` backend,
* those instances will be on different machines and ports,
* I want to use an ambassador to abstract those details.

The ambassador will be:

* a container using the name `api` (or a link),
* passed the list of backends to use (statically or dynamically),
* running a load balancer (e.g. HAProxy or NGINX),
* dispatching requests across all backends transparently.

---

## "Ambassador" is a *pattern*

There are many ways to implement the pattern.

Different deployments will use different underlying technologies.

* On-premise deployments with a trusted network can track
  container locations in e.g. Zookeeper, and generate HAproxy
  configurations each time a location key changes.
* Public cloud deployments or deployments across unsafe
  networks can add TLS encryption.
* Ad-hoc deployments can use a master-less discovery protocol
  like avahi to register and discover services.
* It is also possible to do one-shot reconfiguration of the
  ambassadors. It is slightly less dynamic but has far fewer
  requirements.
* Ambassadors can be used in addition to, or instead of, overlay networks.

---

## Service meshes

* A service mesh is a configurable network layer.

* It can provide service discovery, high availability, load balancing, observability...

* Service meshes are particularly useful for microservices applications.

* Service meshes are often implemented as proxies.

* Applications connect to the service mesh, which relays the connection where needed.

*Does that sound familiar?*

---

## Ambassadors and service meshes

* When using a service mesh, a "sidecar container" is often used as a proxy

* Our services connect (transparently) to that sidecar container

* That sidecar container figures out where to forward the traffic

... Does that sound familiar?

(It should, because service meshes are essentially app-wide or cluster-wide ambassadors!)

---

## Some popular service meshes

... And related projects:

* [Consul Connect](https://www.consul.io/docs/connect/index.html)
  <br/>
  Transparently secures service-to-service connections with mTLS.

* [Gloo](https://gloo.solo.io/)
  <br/>
  API gateway that can interconnect applications on VMs, containers, and serverless.

* [Istio](https://istio.io/)
  <br/>
  A popular service mesh.

* [Linkerd](https://linkerd.io/)
  <br/>
  Another popular service mesh.

---

## Learning more about service meshes

A few blog posts about service meshes:

* [Containers, microservices, and service meshes](http://jpetazzo.github.io/2019/05/17/containers-microservices-service-meshes/)
  <br/>
  Provides historical context: how did we do before service meshes were invented?

* [Do I Need a Service Mesh?](https://www.nginx.com/blog/do-i-need-a-service-mesh/)
  <br/>
  Explains the purpose of service meshes. Illustrates some NGINX features.

* [Do you need a service mesh?](https://www.oreilly.com/ideas/do-you-need-a-service-mesh)
  <br/>
  Includes high-level overview and definitions.

* [What is Service Mesh and Why Do We Need It?](https://containerjournal.com/2018/12/12/what-is-service-mesh-and-why-do-we-need-it/)
  <br/>
  Includes a step-by-step demo of Linkerd.

And a video:

* [What is a Service Mesh, and Do I Need One When Developing Microservices?](https://www.datawire.io/envoyproxy/service-mesh/)
