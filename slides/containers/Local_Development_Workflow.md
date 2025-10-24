
class: title

# Local development workflow with Docker

![Construction site](images/title-local-development-workflow-with-docker.jpg)

---

## Objectives

At the end of this section, you will be able to:

* Share code between container and host.

* Use a simple local development workflow.

---

## Local development in a container

We want to solve the following issues:

- "Works on my machine"

- "Not the same version"

- "Missing dependency"

By using Docker containers, we will get a consistent development environment.

---

## Working on the "namer" application

* We have to work on some application whose code is at:

  https://github.com/jpetazzo/namer.

* What is it? We don't know yet!

* Let's download the code.

```bash
$ git clone https://github.com/jpetazzo/namer
```

---

## Looking at the code

```bash
$ cd namer
$ ls -1
company_name_generator.rb
config.ru
docker-compose.yml
Dockerfile
Gemfile
```

--

Aha, a `Gemfile`! This is Ruby. Probably. We know this. Maybe?

---

## Looking at the `Dockerfile`

```dockerfile
FROM ruby

COPY . /src
WORKDIR /src
RUN bundler install

CMD ["rackup", "--host", "0.0.0.0"]
EXPOSE 9292
```

* This application is using a base `ruby` image.
* The code is copied in `/src`.
* Dependencies are installed with `bundler`.
* The application is started with `rackup`.
* It is listening on port 9292.

---

## Building and running the "namer" application

* Let's build the application with the `Dockerfile`!

--

```bash
$ docker build -t namer .
```

--

* Then run it. *We need to expose its ports.*

--

```bash
$ docker run -dP namer
```

--

* Check on which port the container is listening.

--

```bash
$ docker ps -l
```

---

## Connecting to our application

* Point our browser to our Docker node, on the port allocated to the container.

--

* Hit "reload" a few times.

--

* This is an enterprise-class, carrier-grade, ISO-compliant company name generator!

  (With 50% more bullshit than the average competition!)

  (Wait, was that 50% more, or 50% less? *Anyway!*)

  ![web application 1](images/webapp-in-blue.png)

---

## Making changes to the code

Option 1:

* Edit the code locally
* Rebuild the image
* Re-run the container

Option 2:

* Enter the container (with `docker exec`)
* Install an editor
* Make changes from within the container

Option 3:

* Use a *bind mount* to share local files with the container
* Make changes locally
* Changes are reflected in the container

---

## Our first volume

We will tell Docker to map the current directory to `/src` in the container.

```bash
$ docker run -d -v $(pwd):/src -P namer
```

* `-d`: the container should run in detached mode (in the background).

* `-v`: the following host directory should be mounted inside the container.

* `-P`: publish all the ports exposed by this image.

* `namer` is the name of the image we will run.

* We don't specify a command to run because it is already set in the Dockerfile via `CMD`.

Note: on Windows, replace `$(pwd)` with `%cd%` (or `${pwd}` if you use PowerShell).

---

## Mounting volumes inside containers

The `-v` flag mounts a directory from your host into your Docker container.

The flag structure is:

```bash
[host-path]:[container-path]:[rw|ro]
```

* `[host-path]` and `[container-path]` are created if they don't exist.

* You can control the write status of the volume with the `ro` and
  `rw` options.

* If you don't specify `rw` or `ro`, it will be `rw` by default.

---

class: extra-details

## Hold your horses... and your mounts

- The `-v /path/on/host:/path/in/container` syntax is the "old" syntax

- The modern syntax looks like this:

  `--mount type=bind,source=/path/on/host,target=/path/in/container`

- `--mount` is more explicit, but `-v` is quicker to type

- `--mount` supports all mount types; `-v` doesn't support `tmpfs` mounts

- `--mount` fails if the path on the host doesn't exist; `-v` creates it

With the new syntax, our command becomes:
```bash
docker run --mount=type=bind,source=$(pwd),target=/src -dP namer
```

---

## Testing the development container

* Check the port used by our new container.

```bash
$ docker ps -l
CONTAINER ID  IMAGE  COMMAND  CREATED        STATUS  PORTS                   NAMES
045885b68bc5  namer  rackup   3 seconds ago  Up ...  0.0.0.0:32770->9292/tcp ...
```

* Open the application in your web browser.

---

## Making a change to our application

Our customer really doesn't like the color of our text. Let's change it.

```bash
$ vi company_name_generator.rb
```

And change

```css
color: royalblue;
```

To:

```css
color: red;
```

---

## Viewing our changes

* Reload the application in our browser.

--

* The color should have changed.

  ![web application 2](images/webapp-in-red.png)

---

## Understanding volumes

- Volumes are *not* copying or synchronizing files between the host and the container

- Changes made in the host are immediately visible in the container (and vice versa)

- When running on Linux:

  - volumes and bind mounts correspond to directories on the host

  - if Docker runs in a Linux VM, these directories are in the Linux VM

- When running on Docker Desktop:

  - volumes correspond to directories in a small Linux VM running Docker

  - access to bind mounts is translated to host filesystem access
    <br/>
    (a bit like a network filesystem)

---

class: extra-details

## Docker Desktop caveats

- When running Docker natively on Linux, accessing a mount = native I/O

- When running Docker Desktop, accessing a bind mount = file access translation

- That file access translation has relatively good performance *in general*

  (watch out, however, for that big `npm install` working on a bind mount!)

- There are some corner cases when watching files (with mechanisms like inotify)

- Features like "live reload" or programs like `entr` don't always behave properly

  (due to e.g. file attribute caching, and other interesting details!)

---

## Recap of the development workflow

1. Write a Dockerfile to build an image containing our development environment.
   <br/>
   (Rails, Django, ... and all the dependencies for our app)

2. Start a container from that image.
   <br/>
   Use the `-v` flag to mount our source code inside the container.

3. Edit the source code outside the container, using familiar tools.
   <br/>
   (vim, emacs, textmate...)

4. Test the application.
   <br/>
   (Some frameworks pick up changes automatically.
   <br/>Others require you to Ctrl-C + restart after each modification.)

5. Iterate and repeat steps 3 and 4 until satisfied.

6. When done, commit+push source code changes.

---

class: extra-details

## Stopping the container

Now that we're done let's stop our container.

```bash
$ docker stop <yourContainerID>
```

And remove it.

```bash
$ docker rm <yourContainerID>
```

---

## Section summary

We've learned how to:

* Share code between container and host.

* Set our working directory.

* Use a simple local development workflow.

???

:EN:Developing with containers
:EN:- “Containerize” a development environment

:FR:Développer au jour le jour
:FR:- « Containeriser » son environnement de développement
