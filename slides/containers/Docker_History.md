# History of containers ... and Docker

---

## First experimentations

* [IBM VM/370 (1972)](https://en.wikipedia.org/wiki/VM_%28operating_system%29)

* [Linux VServers (2001)](http://www.solucorp.qc.ca/changes.hc?projet=vserver)

* [Solaris Containers (2004)](https://en.wikipedia.org/wiki/Solaris_Containers)

* [FreeBSD jails (1999-2000)](https://www.freebsd.org/cgi/man.cgi?query=jail&sektion=8&manpath=FreeBSD+4.0-RELEASE)

Containers have been around for a *very long time* indeed.

(See [this excellent blog post by Serge Hallyn](https://s3hh.wordpress.com/2018/03/22/history-of-containers/) for more historic details.)

---

class: pic

## The VPS age (until 2007-2008)

![lightcont](images/containers-as-lightweight-vms.png)

---

## Containers = cheaper than VMs

* Users: hosting providers.

* Highly specialized audience with strong ops culture.

---

class: pic

## The PAAS period (2008-2013)

![heroku 2007](images/heroku-first-homepage.png)

---

## Containers = easier than VMs

* I can't speak for Heroku, but containers were (one of) dotCloud's secret weapon

* dotCloud was operating a PaaS, using a custom container engine.

* This engine was based on OpenVZ (and later, LXC) and AUFS.

* It started (circa 2008) as a single Python script.

* By 2012, the engine had multiple (~10) Python components.
  <br/>(and ~100 other micro-services!)

* End of 2012, dotCloud refactors this container engine.

* The codename for this project is "Docker."

---

## First public release of Docker

* March 2013, PyCon, Santa Clara:
  <br/>"Docker" is shown to a public audience for the first time.

* It is released with an open source license.

* Very positive reactions and feedback!

* The dotCloud team progressively shifts to Docker development.

* The same year, dotCloud changes name to Docker.

* In 2014, the PaaS activity is sold.

---

## Docker early days (2013-2014)

---

## First users of Docker

* PAAS builders (Flynn, Dokku, Tsuru, Deis...)

* PAAS users (those big enough to justify building their own)

* CI platforms

* developers, developers, developers, developers

---

## Positive feedback loop

* In 2013, the technology under containers (cgroups, namespaces, copy-on-write storage...)
  had many blind spots.

* The growing popularity of Docker and containers exposed many bugs.

* As a result, those bugs were fixed, resulting in better stability for containers.

* Any decent hosting/cloud provider can run containers today.

* Containers become a great tool to deploy/move workloads to/from on-prem/cloud.

---

## Maturity (2015-2016)

---

## Docker becomes an industry standard

* Docker reaches the symbolic 1.0 milestone.

* Existing systems like Mesos and Cloud Foundry add Docker support.

* Standardization around the OCI (Open Containers Initiative).

* Other container engines are developed.

* Creation of the CNCF (Cloud Native Computing Foundation).

---

## Docker becomes a platform

* The initial container engine is now known as "Docker Engine."

* Other tools are added:
  * Docker Compose (formerly "Fig")
  * Docker Machine
  * Docker Swarm
  * Kitematic
  * Docker Cloud (formerly "Tutum")
  * Docker Datacenter
  * etc.

* Docker Inc. launches commercial offers.
