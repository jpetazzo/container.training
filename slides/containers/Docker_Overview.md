# Why Docker?

The original "Docker pitch" (back in 2013!) made a lot of comparisons
with the shipping industry, and its transformation thanks to
the *intermodal shipping container.*

More than a decade later... Why is Docker still relevant, and
what are we using it for?

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
docker compose up
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
