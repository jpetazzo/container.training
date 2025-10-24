
class: title

# More Dockerfile Instructions

![construction](images/title-advanced-dockerfiles.jpg)

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

class: extra-details

## The `USER` instruction

The `USER` instruction sets the user name or UID to use when running
the image.

It can be used multiple times to change back to root or to another user.

???

:EN:- Advanced Dockerfile syntax
:FR:- Dockerfile niveau expert
