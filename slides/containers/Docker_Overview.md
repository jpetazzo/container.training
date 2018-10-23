# Docker 30,000ft overview

In this lesson, we will learn about:

* Why containers (non-technical elevator pitch)

* Why containers (technical elevator pitch)

* How Docker helps us to build, ship, and run

* The history of containers

We won't actually run Docker or containers in this chapter (yet!).

Don't worry, we will get to that fast enough!

---

## Elevator pitch

### (for your manager, your boss...)

---

## OK... Why the buzz around containers?

* The software industry has changed

* Before:
  * monolithic applications
  * long development cycles
  * single environment
  * slowly scaling up

* Now:
  * decoupled services
  * fast, iterative improvements
  * multiple environments
  * quickly scaling out

---

## Deployment becomes very complex

* Many different stacks:
  * languages
  * frameworks
  * databases

* Many different targets:
  * individual development environments
  * pre-production, QA, staging...
  * production: on prem, cloud, hybrid

---

class: pic

## The deployment problem

![problem](images/shipping-software-problem.png)

---

class: pic

## The matrix from hell

![matrix](images/shipping-matrix-from-hell.png)

---

class: pic

## The parallel with the shipping industry

![history](images/shipping-industry-problem.png)

---

class: pic

## Intermodal shipping containers

![shipping](images/shipping-industry-solution.png)

---

class: pic

## A new shipping ecosystem

![shipeco](images/shipping-indsutry-results.png)

---

class: pic

## A shipping container system for applications

![shipapp](images/shipping-software-solution.png)

---

class: pic

## Eliminate the matrix from hell

![elimatrix](images/shipping-matrix-solved.png)

---

## Results

* [Dev-to-prod reduced from 9 months to 15 minutes (ING)](
  https://www.docker.com/sites/default/files/CS_ING_01.25.2015_1.pdf)

* [Continuous integration job time reduced by more than 60% (BBC)](
  https://www.docker.com/sites/default/files/CS_BBCNews_01.25.2015_1.pdf)

* [Deploy 100 times a day instead of once a week (GILT)](
  https://www.docker.com/sites/default/files/CS_Gilt%20Groupe_03.18.2015_0.pdf)

* [70% infrastructure consolidation (MetLife)](
  https://www.docker.com/customers/metlife-transforms-customer-experience-legacy-and-microservices-mashup)

* [60% infrastructure consolidation (Intesa Sanpaolo)](
  https://blog.docker.com/2017/11/intesa-sanpaolo-builds-resilient-foundation-banking-docker-enterprise-edition/)

* [14x application density; 60% of legacy datacenter migrated in 4 months (GE Appliances)](
  https://www.docker.com/customers/ge-uses-docker-enable-self-service-their-developers)

* etc.

---

## Elevator pitch

### (for your fellow devs and ops)

---

## Escape dependency hell

1. Write installation instructions into an `INSTALL.txt` file

2. Using this file, write an `install.sh` script that works *for you*

3. Turn this file into a `Dockerfile`, test it on your machine

4. If the Dockerfile builds on your machine, it will build *anywhere*

5. Rejoice as you escape dependency hell and "works on my machine"

Never again "worked in dev - ops problem now!"

---

## On-board developers and contributors rapidly

1. Write Dockerfiles for your application components

2. Use pre-made images from the Docker Hub (mysql, redis...)

3. Describe your stack with a Compose file

4. On-board somebody with two commands:

```bash
git clone ...
docker-compose up
```

With this, you can create development, integration, QA environments in minutes!

---

class: extra-details

## Implement reliable CI easily

1. Build test environment with a Dockerfile or Compose file

2. For each test run, stage up a new container or stack

3. Each run is now in a clean environment

4. No pollution from previous tests

Way faster and cheaper than creating VMs each time!

---

class: extra-details

## Use container images as build artefacts

1. Build your app from Dockerfiles

2. Store the resulting images in a registry

3. Keep them forever (or as long as necessary)

4. Test those images in QA, CI, integration...

5. Run the same images in production

6. Something goes wrong? Rollback to previous image

7. Investigating old regression? Old image has your back!

Images contain all the libraries, dependencies, etc. needed to run the app.

---

class: extra-details

## Decouple "plumbing" from application logic

1. Write your code to connect to named services ("db", "api"...)

2. Use Compose to start your stack

3. Docker will setup per-container DNS resolver for those names

4. You can now scale, add load balancers, replication ... without changing your code

Note: this is not covered in this intro level workshop!

---

class: extra-details

## What did Docker bring to the table?

### Docker before/after

---

class: extra-details

## Formats and APIs, before Docker

* No standardized exchange format.
  <br/>(No, a rootfs tarball is *not* a format!)

* Containers are hard to use for developers.
  <br/>(Where's the equivalent of `docker run debian`?)

* As a result, they are *hidden* from the end users.

* No re-usable components, APIs, tools.
  <br/>(At best: VM abstractions, e.g. libvirt.)

Analogy: 

* Shipping containers are not just steel boxes.
* They are steel boxes that are a standard size, with the same hooks and holes.

---

class: extra-details

## Formats and APIs, after Docker

* Standardize the container format, because containers were not portable.

* Make containers easy to use for developers.

* Emphasis on re-usable components, APIs, ecosystem of standard tools.

* Improvement over ad-hoc, in-house, specific tools.

---

class: extra-details

## Shipping, before Docker

* Ship packages: deb, rpm, gem, jar, homebrew...

* Dependency hell.

* "Works on my machine."

* Base deployment often done from scratch (debootstrap...) and unreliable.

---

class: extra-details

## Shipping, after Docker

* Ship container images with all their dependencies.

* Images are bigger, but they are broken down into layers.

* Only ship layers that have changed.

* Save disk, network, memory usage.

---

class: extra-details

## Example

Layers:

* CentOS
* JRE
* Tomcat
* Dependencies
* Application JAR
* Configuration

---

class: extra-details

## Devs vs Ops, before Docker

* Drop a tarball (or a commit hash) with instructions.

* Dev environment very different from production.

* Ops don't always have a dev environment themselves ...

* ... and when they do, it can differ from the devs'.

* Ops have to sort out differences and make it work ...

* ... or bounce it back to devs.

* Shipping code causes frictions and delays.

---

class: extra-details

## Devs vs Ops, after Docker

* Drop a container image or a Compose file.

* Ops can always run that container image.

* Ops can always run that Compose file.

* Ops still have to adapt to prod environment,
  but at least they have a reference point.

* Ops have tools allowing to use the same image
  in dev and prod.

* Devs can be empowered to make releases themselves
  more easily.
