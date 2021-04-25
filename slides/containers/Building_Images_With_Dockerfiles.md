
class: title

# Building Docker images with a Dockerfile

![Construction site with containers](images/title-building-docker-images-with-a-dockerfile.jpg)

---

## Objectives

We will build a container image automatically, with a `Dockerfile`.

At the end of this lesson, you will be able to:

* Write a `Dockerfile`.

* Build an image from a `Dockerfile`.

---

## `Dockerfile` overview

* A `Dockerfile` is a build recipe for a Docker image.

* It contains a series of instructions telling Docker how an image is constructed.

* The `docker build` command builds an image from a `Dockerfile`.

---

## Writing our first `Dockerfile`

Our Dockerfile must be in a **new, empty directory**.

1. Create a directory to hold our `Dockerfile`.

```bash
$ mkdir myimage
```

2. Create a `Dockerfile` inside this directory.

```bash
$ cd myimage
$ vim Dockerfile
```

Of course, you can use any other editor of your choice.

---

## Type this into our Dockerfile...

```dockerfile
FROM ubuntu
RUN apt-get update
RUN apt-get install figlet
```

* `FROM` indicates the base image for our build.

* Each `RUN` line will be executed by Docker during the build.

* Our `RUN` commands **must be non-interactive.**
  <br/>(No input can be provided to Docker during the build.)

* In many cases, we will add the `-y` flag to `apt-get`.

---

## Build it!

Save our file, then execute:

```bash
$ docker build -t figlet .
```

* `-t` indicates the tag to apply to the image.

* `.` indicates the location of the *build context*.

We will talk more about the build context later.

To keep things simple for now: this is the directory where our Dockerfile is located.

---

## What happens when we build the image?

It depends if we're using BuildKit or not!

If there are lots of blue lines and the first line looks like this:
```
[+] Building 1.8s (4/6)
```
... then we're using BuildKit.

If the output is mostly black-and-white and the first line looks like this:
```
Sending build context to Docker daemon  2.048kB
```
... then we're using the "classic" or "old-style" builder.

---

## To BuildKit or Not To BuildKit

Classic builder:

- copies the whole "build context" to the Docker Engine

- linear (processes lines one after the other)

- requires a full Docker Engine

BuildKit:

- only transfers parts of the "build context" when needed

- will parallelize operations (when possible)

- can run in non-privileged containers (e.g. on Kubernetes)

---

## With the classic builder

The output of `docker build` looks like this:

.small[
```bash
docker build -t figlet .
Sending build context to Docker daemon  2.048kB
Step 1/3 : FROM ubuntu
 ---> f975c5035748
Step 2/3 : RUN apt-get update
 ---> Running in e01b294dbffd
(...output of the RUN command...)
Removing intermediate container e01b294dbffd
 ---> eb8d9b561b37
Step 3/3 : RUN apt-get install figlet
 ---> Running in c29230d70f9b
(...output of the RUN command...)
Removing intermediate container c29230d70f9b
 ---> 0dfd7a253f21
Successfully built 0dfd7a253f21
Successfully tagged figlet:latest
```
]

* The output of the `RUN` commands has been omitted.
* Let's explain what this output means.

---

## Sending the build context to Docker

```bash
Sending build context to Docker daemon 2.048 kB
```

* The build context is the `.` directory given to `docker build`.

* It is sent (as an archive) by the Docker client to the Docker daemon.

* This allows to use a remote machine to build using local files.

* Be careful (or patient) if that directory is big and your link is slow.

* You can speed up the process with a [`.dockerignore`](https://docs.docker.com/engine/reference/builder/#dockerignore-file) file

  * It tells docker to ignore specific files in the directory

  * Only ignore files that you won't need in the build context!

---

## Executing each step

```bash
Step 2/3 : RUN apt-get update
 ---> Running in e01b294dbffd
(...output of the RUN command...)
Removing intermediate container e01b294dbffd
 ---> eb8d9b561b37
```

* A container (`e01b294dbffd`) is created from the base image.

* The `RUN` command is executed in this container.

* The container is committed into an image (`eb8d9b561b37`).

* The build container (`e01b294dbffd`) is removed.

* The output of this step will be the base image for the next one.

---

## With BuildKit

.small[
```bash
[+] Building 7.9s (7/7) FINISHED
 => [internal] load build definition from Dockerfile                                                 0.0s
 => => transferring dockerfile: 98B                                                                  0.0s
 => [internal] load .dockerignore                                                                    0.0s
 => => transferring context: 2B                                                                      0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                     1.2s
 => [1/3] FROM docker.io/library/ubuntu@sha256:cf31af331f38d1d7158470e095b132acd126a7180a54f263d386  3.2s
 => => resolve docker.io/library/ubuntu@sha256:cf31af331f38d1d7158470e095b132acd126a7180a54f263d386  0.0s
 => => sha256:cf31af331f38d1d7158470e095b132acd126a7180a54f263d386da88eb681d93 1.20kB / 1.20kB       0.0s
 => => sha256:1de4c5e2d8954bf5fa9855f8b4c9d3c3b97d1d380efe19f60f3e4107a66f5cae 943B / 943B           0.0s
 => => sha256:6a98cbe39225dadebcaa04e21dbe5900ad604739b07a9fa351dd10a6ebad4c1b 3.31kB / 3.31kB       0.0s
 => => sha256:80bc30679ac1fd798f3241208c14accd6a364cb8a6224d1127dfb1577d10554f 27.14MB / 27.14MB     2.3s
 => => sha256:9bf18fab4cfbf479fa9f8409ad47e2702c63241304c2cdd4c33f2a1633c5f85e 850B / 850B           0.5s
 => => sha256:5979309c983a2adeff352538937475cf961d49c34194fa2aab142effe19ed9c1 189B / 189B           0.4s
 => => extracting sha256:80bc30679ac1fd798f3241208c14accd6a364cb8a6224d1127dfb1577d10554f            0.7s
 => => extracting sha256:9bf18fab4cfbf479fa9f8409ad47e2702c63241304c2cdd4c33f2a1633c5f85e            0.0s
 => => extracting sha256:5979309c983a2adeff352538937475cf961d49c34194fa2aab142effe19ed9c1            0.0s
 => [2/3] RUN apt-get update                                                                         2.5s
 => [3/3] RUN apt-get install figlet                                                                 0.9s
 => exporting to image                                                                               0.1s
 => => exporting layers                                                                              0.1s
 => => writing image sha256:3b8aee7b444ab775975dfba691a72d8ac24af2756e0a024e056e3858d5a23f7c         0.0s
 => => naming to docker.io/library/figlet                                                            0.0s
 ```
 ]

---

## Understanding BuildKit output

- BuildKit transfers the Dockerfile and the *build context*

  (these are the first two `[internal]` stages)

- Then it executes the steps defined in the Dockerfile

  (`[1/3]`, `[2/3]`, `[3/3]`)

- Finally, it exports the result of the build

  (image definition + collection of layers)

---

class: extra-details

## BuildKit plain output

- When running BuildKit in e.g. a CI pipeline, its output will be different

- We can see the same output format by using `--progress=plain`

---

## The caching system

If you run the same build again, it will be instantaneous. Why?

* After each build step, Docker takes a snapshot of the resulting image.

* Before executing a step, Docker checks if it has already built the same sequence.

* Docker uses the exact strings defined in your Dockerfile, so:

  * `RUN apt-get install figlet cowsay`
    <br/> is different from
    <br/> `RUN apt-get install cowsay figlet`

  * `RUN apt-get update` is not re-executed when the mirrors are updated

You can force a rebuild with `docker build --no-cache ...`.

---

## Running the image

The resulting image is not different from the one produced manually.

```bash
$ docker run -ti figlet
root@91f3c974c9a1:/# figlet hello
 _          _ _       
| |__   ___| | | ___  
| '_ \ / _ \ | |/ _ \ 
| | | |  __/ | | (_) |
|_| |_|\___|_|_|\___/ 
```


Yay! 🎉

---

## Using image and viewing history

The `history` command lists all the layers composing an image.

For each layer, it shows its creation time, size, and creation command.

When an image was built with a Dockerfile, each layer corresponds to
a line of the Dockerfile.

```bash
$ docker history figlet
IMAGE         CREATED            CREATED BY                     SIZE
f9e8f1642759  About an hour ago  /bin/sh -c apt-get install fi  1.627 MB
7257c37726a1  About an hour ago  /bin/sh -c apt-get update      21.58 MB
07c86167cdc4  4 days ago         /bin/sh -c #(nop) CMD ["/bin   0 B
<missing>     4 days ago         /bin/sh -c sed -i 's/^#\s*\(   1.895 kB
<missing>     4 days ago         /bin/sh -c echo '#!/bin/sh'    194.5 kB
<missing>     4 days ago         /bin/sh -c #(nop) ADD file:b   187.8 MB
```

---

class: extra-details

## Why `sh -c`?

* On UNIX, to start a new program, we need two system calls:

  - `fork()`, to create a new child process;

  - `execve()`, to replace the new child process with the program to run.

* Conceptually, `execve()` works like this:

  `execve(program, [list, of, arguments])`

* When we run a command, e.g. `ls -l /tmp`, something needs to parse the command.

  (i.e. split the program and its arguments into a list.)

* The shell is usually doing that.

  (It also takes care of expanding environment variables and special things like `~`.)

---

class: extra-details

## Why `sh -c`?

* When we do `RUN ls -l /tmp`, the Docker builder needs to parse the command.

* Instead of implementing its own parser, it outsources the job to the shell.

* That's why we see `sh -c ls -l /tmp` in that case.

* But we can also do the parsing jobs ourselves.

* This means passing `RUN` a list of arguments.

* This is called the *exec syntax*.

---

## Shell syntax vs exec syntax

Dockerfile commands that execute something can have two forms:

* plain string, or *shell syntax*:
  <br/>`RUN apt-get install figlet`

* JSON list, or *exec syntax*:
  <br/>`RUN ["apt-get", "install", "figlet"]`

We are going to change our Dockerfile to see how it affects the resulting image.

---

## Using exec syntax in our Dockerfile

Let's change our Dockerfile as follows!

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
```

Then build the new Dockerfile.

```bash
$ docker build -t figlet .
```

---

## History with exec syntax

Compare the new history:

```bash
$ docker history figlet
IMAGE         CREATED            CREATED BY                     SIZE
27954bb5faaf  10 seconds ago     apt-get install figlet         1.627 MB
7257c37726a1  About an hour ago  /bin/sh -c apt-get update      21.58 MB
07c86167cdc4  4 days ago         /bin/sh -c #(nop) CMD ["/bin   0 B
<missing>     4 days ago         /bin/sh -c sed -i 's/^#\s*\(   1.895 kB
<missing>     4 days ago         /bin/sh -c echo '#!/bin/sh'    194.5 kB
<missing>     4 days ago         /bin/sh -c #(nop) ADD file:b   187.8 MB
```

* Exec syntax specifies an *exact* command to execute.

* Shell syntax specifies a command to be wrapped within `/bin/sh -c "..."`.

---

## When to use exec syntax and shell syntax

* shell syntax:

  * is easier to write
  * interpolates environment variables and other shell expressions
  * creates an extra process (`/bin/sh -c ...`) to parse the string
  * requires `/bin/sh` to exist in the container

* exec syntax:

  * is harder to write (and read!)
  * passes all arguments without extra processing
  * doesn't create an extra process
  * doesn't require `/bin/sh` to exist in the container

---

## Pro-tip: the `exec` shell built-in

POSIX shells have a built-in command named `exec`.

`exec` should be followed by a program and its arguments.

From a user perspective:

- it looks like the shell exits right away after the command execution,

- in fact, the shell exits just *before* command execution;

- or rather, the shell gets *replaced* by the command.

---

## Example using `exec`

```dockerfile
CMD exec figlet -f script hello
```

In this example, `sh -c` will still be used, but
`figlet` will be PID 1 in the container.

The shell gets replaced by `figlet` when `figlet` starts execution.

This allows to run processes as PID 1 without using JSON.

???

:EN:- Towards automated, reproducible builds
:EN:- Writing our first Dockerfile
:FR:- Rendre le processus automatique et reproductible
:FR:- Écrire son premier Dockerfile
