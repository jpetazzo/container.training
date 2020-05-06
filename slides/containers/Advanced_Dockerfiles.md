
class: title

# Advanced Dockerfile Syntax

![construction](images/title-advanced-dockerfiles.jpg)

---

## Objectives

We have seen simple Dockerfiles to illustrate how Docker build
container images.

In this section, we will give a recap of the Dockerfile syntax,
and introduce advanced Dockerfile commands that we might
come across sometimes; or that we might want to use in some
specific scenarios.

---

## `Dockerfile` usage summary

* `Dockerfile` instructions are executed in order.

* Each instruction creates a new layer in the image.

* Docker maintains a cache with the layers of previous builds.

* When there are no changes in the instructions and files making a layer,
  the builder re-uses the cached layer, without executing the instruction for that layer.

* The `FROM` instruction MUST be the first non-comment instruction.

* Lines starting with `#` are treated as comments.

* Some instructions (like `CMD` or `ENTRYPOINT`) update a piece of metadata.

  (As a result, each call to these instructions makes the previous one useless.)

---

## The `RUN` instruction

The `RUN` instruction can be specified in two ways.

With shell wrapping, which runs the specified command inside a shell,
with `/bin/sh -c`:

```dockerfile
RUN apt-get update
```

Or using the `exec` method, which avoids shell string expansion, and
allows execution in images that don't have `/bin/sh`:

```dockerfile
RUN [ "apt-get", "update" ]
```

---

## More about the `RUN` instruction

`RUN` will do the following:

* Execute a command.
* Record changes made to the filesystem.
* Work great to install libraries, packages, and various files.

`RUN` will NOT do the following:

* Record state of *processes*.
* Automatically start daemons.

If you want to start something automatically when the container runs,
you should use `CMD` and/or `ENTRYPOINT`.

---

## Collapsing layers

It is possible to execute multiple commands in a single step:

```dockerfile
RUN apt-get update && apt-get install -y wget && apt-get clean
```

It is also possible to break a command onto multiple lines:

```dockerfile
RUN apt-get update \
 && apt-get install -y wget \
 && apt-get clean
```

---

## The `EXPOSE` instruction

The `EXPOSE` instruction tells Docker what ports are to be published
in this image.

```dockerfile
EXPOSE 8080
EXPOSE 80 443
EXPOSE 53/tcp 53/udp
```

* All ports are private by default.

* Declaring a port with `EXPOSE` is not enough to make it public.

* The `Dockerfile` doesn't control on which port a service gets exposed.

---

## Exposing ports

* When you `docker run -p <port> ...`, that port becomes public.

    (Even if it was not declared with `EXPOSE`.)

* When you `docker run -P ...` (without port number), all ports
  declared with `EXPOSE` become public.

A *public port* is reachable from other containers and from outside the host.

A *private port* is not reachable from outside.

---

## The `COPY` instruction

The `COPY` instruction adds files and content from your host into the
image.

```dockerfile
COPY . /src
```

This will add the contents of the *build context* (the directory
passed as an argument to `docker build`) to the directory `/src`
in the container.

---

## Build context isolation

Note: you can only reference files and directories *inside* the
build context. Absolute paths are taken as being anchored to
the build context, so the two following lines are equivalent:

```dockerfile
COPY . /src
COPY / /src
```

Attempts to use `..` to get out of the build context will be
detected and blocked with Docker, and the build will fail.

Otherwise, a `Dockerfile` could succeed on host A, but fail on host B.

---

## `ADD`

`ADD` works almost like `COPY`, but has a few extra features.

`ADD` can get remote files:

```dockerfile
ADD http://www.example.com/webapp.jar /opt/
```

This would download the `webapp.jar` file and place it in the `/opt`
directory.

`ADD` will automatically unpack zip files and tar archives:

```dockerfile
ADD ./assets.zip /var/www/htdocs/assets/
```

This would unpack `assets.zip` into `/var/www/htdocs/assets`.

*However,* `ADD` will not automatically unpack remote archives.

---

## `ADD`, `COPY`, and the build cache

* Before creating a new layer, Docker checks its build cache.

* For most Dockerfile instructions, Docker only looks at the
  `Dockerfile` content to do the cache lookup.

* For `ADD` and `COPY` instructions, Docker also checks if the files
  to be added to the container have been changed.

* `ADD` always needs to download the remote file before
  it can check if it has been changed.

  (It cannot use,
  e.g., ETags or If-Modified-Since headers.)

---

## `VOLUME`

The `VOLUME` instruction tells Docker that a specific directory
should be a *volume*.

```dockerfile
VOLUME /var/lib/mysql
```

Filesystem access in volumes bypasses the copy-on-write layer,
offering native performance to I/O done in those directories.

Volumes can be attached to multiple containers, allowing to
"port" data over from a container to another, e.g. to
upgrade a database to a newer version.

It is possible to start a container in "read-only" mode.
The container filesystem will be made read-only, but volumes
can still have read/write access if necessary.

---

## The `WORKDIR` instruction

The `WORKDIR` instruction sets the working directory for subsequent
instructions.

It also affects `CMD` and `ENTRYPOINT`, since it sets the working
directory used when starting the container.
   
```dockerfile
WORKDIR /src
```

You can specify `WORKDIR` again to change the working directory for
further operations.

---

## The `ENV` instruction

The `ENV` instruction specifies environment variables that should be
set in any container launched from the image.

```dockerfile
ENV WEBAPP_PORT 8080
```

This will result in an environment variable being created in any
containers created from this image of

```bash
WEBAPP_PORT=8080
```

You can also specify environment variables when you use `docker run`.

```bash
$ docker run -e WEBAPP_PORT=8000 -e WEBAPP_HOST=www.example.com ...
```

---

## The `USER` instruction

The `USER` instruction sets the user name or UID to use when running
the image.

It can be used multiple times to change back to root or to another user.

---

## The `CMD` instruction

The `CMD` instruction is a default command run when a container is
launched from the image.

```dockerfile
CMD [ "nginx", "-g", "daemon off;" ]
```

Means we don't need to specify `nginx -g "daemon off;"` when running the
container.

Instead of:

```bash
$ docker run <dockerhubUsername>/web_image nginx -g "daemon off;"
```

We can just do:

```bash
$ docker run <dockerhubUsername>/web_image
```

---

## More about the `CMD` instruction

Just like `RUN`, the `CMD` instruction comes in two forms.
The first executes in a shell:

```dockerfile
CMD nginx -g "daemon off;"
```

The second executes directly, without shell processing:

```dockerfile
CMD [ "nginx", "-g", "daemon off;" ]
```

---

class: extra-details

## Overriding the `CMD` instruction

The `CMD` can be overridden when you run a container.

```bash
$ docker run -it <dockerhubUsername>/web_image bash
```

Will run `bash` instead of `nginx -g "daemon off;"`.

---

## The `ENTRYPOINT` instruction

The `ENTRYPOINT` instruction is like the `CMD` instruction,
but arguments given on the command line are *appended* to the
entry point.

Note: you have to use the "exec" syntax (`[ "..." ]`).

```dockerfile
ENTRYPOINT [ "/bin/ls" ]
```

If we were to run:

```bash
$ docker run training/ls -l
```

Instead of trying to run `-l`, the container will run `/bin/ls -l`.

---

class: extra-details

## Overriding the `ENTRYPOINT` instruction

The entry point can be overridden as well.

```bash
$ docker run -it training/ls
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr
$ docker run -it --entrypoint bash training/ls
root@d902fb7b1fc7:/#
```

---

## How `CMD` and `ENTRYPOINT` interact

The `CMD` and `ENTRYPOINT` instructions work best when used
together.

```dockerfile
ENTRYPOINT [ "nginx" ]
CMD [ "-g", "daemon off;" ]
```

The `ENTRYPOINT` specifies the command to be run and the `CMD`
specifies its options. On the command line we can then potentially
override the options when needed.

```bash
$ docker run -d <dockerhubUsername>/web_image -t
```

This will override the options `CMD` provided with new flags.

---

## Advanced Dockerfile instructions

* `ONBUILD` lets you stash instructions that will be executed
  when this image is used as a base for another one.
* `LABEL` adds arbitrary metadata to the image.
* `ARG` defines build-time variables (optional or mandatory).
* `STOPSIGNAL` sets the signal for `docker stop` (`TERM` by default).
* `HEALTHCHECK` defines a command assessing the status of the container.
* `SHELL` sets the default program to use for string-syntax RUN, CMD, etc.

---

class: extra-details

## The `ONBUILD` instruction

The `ONBUILD` instruction is a trigger. It sets instructions that will
be executed when another image is built from the image being build.

This is useful for building images which will be used as a base
to build other images.

```dockerfile
ONBUILD COPY . /src
```

* You can't chain `ONBUILD` instructions with `ONBUILD`.
* `ONBUILD` can't be used to trigger `FROM` instructions.

???

:EN:- Advanced Dockerfile syntax
:FR:- Dockerfile niveau expert
