# The container ecosystem

In this chapter, we will talk about a few actors of the container ecosystem.

We have (arbitrarily) decided to focus on two groups:

- the Docker ecosystem,

- the Cloud Native Computing Foundation (CNCF) and its projects.

---

class: pic

## The Docker ecosystem

![The Docker ecosystem in 2015](images/docker-ecosystem-2015.png)

---

## Moby vs. Docker

- Docker Inc. (the company) started Docker (the open source project).

- At some point, it became necessary to differentiate between:

  - the open source project (code base, contributors...),

  - the product that we use to run containers (the engine),

  - the platform that we use to manage containerized applications,

  - the brand.

---

class: pic

![Picture of a Tesla](images/tesla.jpg)

---

## Exercise in brand management

Questions:

--

- What is the brand of the car on the previous slide?

--

- What kind of engine does it have?

--

- Would you say that it's a safe or unsafe car?

--

- Harder question: can you drive from the US West to East coasts with it?

--

The answers to these questions are part of the Tesla brand.

---

## What if ...

- The blueprints for Tesla cars were available for free.

- You could legally build your own Tesla.

- You were allowed to customize it entirely.

  (Put a combustion engine, drive it with a game pad ...)

- You could even sell the customized versions.

--

- ... And call your customized version "Tesla".

--

Would we give the same answers to the questions on the previous slide?

---

## From Docker to Moby

- Docker Inc. decided to split the brand.

- Moby is the open source project.

  (= Components and libraries that you can use, reuse, customize, sell ...)

- Docker is the product.

  (= Software that you can use, buy support contracts ...)

- Docker is made with Moby.

- When Docker Inc. improves the Docker products, it improves Moby.

  (And vice versa.)


---

## Other examples

- *Read the Docs* is an open source project to generate and host documentation.

- You can host it yourself (on your own servers).

- You can also get hosted on readthedocs.org.

- The maintainers of the open source project often receive
  support requests from users of the hosted product ...

- ... And the maintainers of the hosted product often
  receive support requests from users of self-hosted instances.

- Another example:

  *WordPress.com is a blogging platform that is owned and hosted online by
  Automattic. It is run on WordPress, an open source piece of software used by
  bloggers. (Wikipedia)*

---

## Docker CE vs Docker EE

- Docker CE = Community Edition.

- Available on most Linux distros, Mac, Windows.

- Optimized for developers and ease of use.

- Docker EE = Enterprise Edition.

- Available only on a subset of Linux distros + Windows servers.

  (Only available when there is a strong partnership to offer enterprise-class support.)

- Optimized for production use.

- Comes with additional components: security scanning, RBAC ...

---

## The CNCF

- Non-profit, part of the Linux Foundation; founded in December 2015. 

  *The Cloud Native Computing Foundation builds sustainable ecosystems and fosters
  a community around a constellation of high-quality projects that orchestrate
  containers as part of a microservices architecture.*

  *CNCF is an open source software foundation dedicated to making cloud-native computing universal and sustainable.*

- Home of Kubernetes (and many other projects now).

- Funded by corporate memberships.

---

class: pic

![Cloud Native Landscape](https://landscape.cncf.io/images/landscape.png)

