
class: title

# Background containers

![Background containers](images/title-background-containers.jpg)

---

## Objectives

Our first containers were *interactive*.

We will now see how to:

* Run a non-interactive container.
* Run a container in the background.
* List running containers.
* Check the logs of a container.
* Stop a container.
* List stopped containers.

---

## A non-interactive container

We will run a small custom container.

This container just displays the time every second.

```bash
$ docker run jpetazzo/clock
Fri Feb 20 00:28:53 UTC 2015
Fri Feb 20 00:28:54 UTC 2015
Fri Feb 20 00:28:55 UTC 2015
...
```

* This container will run forever.
* To stop it, press `^C`.
* Docker has automatically downloaded the image `jpetazzo/clock`.
* This image is a user image, created by `jpetazzo`.
* We will hear more about user images (and other types of images) later.

---

## When `^C` doesn't work...

Sometimes, `^C` won't be enough.

Why? And how can we stop the container in that case?

---

## What happens when we hit `^C`

`SIGINT` gets sent to the container, which means:

- `SIGINT` gets sent to PID 1 (default case)

- `SIGINT` gets sent to *foreground processes* when running with `-ti`

But there is a special case for PID 1: it ignores all signals!

- except `SIGKILL` and `SIGSTOP`

- except signals handled explicitly

TL,DR: there are many circumstances when `^C` won't stop the container.

---

class: extra-details

## Why is PID 1 special?

- PID 1 has some extra responsibilities:

  - it starts (directly or indirectly) every other process

  - when a process exits, its processes are "reparented" under PID 1

- When PID 1 exits, everything stops:

  - on a "regular" machine, it causes a kernel panic

  - in a container, it kills all the processes

- We don't want PID 1 to stop accidentally

- That's why it has these extra protections

---

## How to stop these containers, then?

- Start another terminal and forget about them

  (for now!)

- We'll shortly learn about `docker kill`

---

## Run a container in the background

Containers can be started in the background, with the `-d` flag (daemon mode):

```bash
$ docker run -d jpetazzo/clock
47d677dcfba4277c6cc68fcaa51f932b544cab1a187c853b7d0caf4e8debe5ad
```

* We don't see the output of the container.
* But don't worry: Docker collects that output and logs it!
* Docker gives us the ID of the container.

---

## List running containers

How can we check that our container is still running?

With `docker ps`, just like the UNIX `ps` command, lists running processes.

```bash
$ docker ps
CONTAINER ID  IMAGE           ...  CREATED        STATUS        ...
47d677dcfba4  jpetazzo/clock  ...  2 minutes ago  Up 2 minutes  ...
```

Docker tells us:

* The (truncated) ID of our container.
* The image used to start the container.
* That our container has been running (`Up`) for a couple of minutes.
* Other information (COMMAND, PORTS, NAMES) that we will explain later.

---

## Starting more containers

Let's start two more containers.

```bash
$ docker run -d jpetazzo/clock
57ad9bdfc06bb4407c47220cf59ce21585dce9a1298d7a67488359aeaea8ae2a
```

```bash
$ docker run -d jpetazzo/clock
068cc994ffd0190bbe025ba74e4c0771a5d8f14734af772ddee8dc1aaf20567d
```

Check that `docker ps` correctly reports all 3 containers.

---

## Viewing only the last container started

When many containers are already running, it can be useful to
see only the last container that was started.

This can be achieved with the `-l` ("Last") flag:

```bash
$ docker ps -l
CONTAINER ID  IMAGE           ...  CREATED        STATUS        ...
068cc994ffd0  jpetazzo/clock  ...  2 minutes ago  Up 2 minutes  ...
```

---

## View only the IDs of the containers

Many Docker commands will work on container IDs: `docker stop`, `docker rm`...

If we want to list only the IDs of our containers (without the other columns
or the header line),
we can use the `-q` ("Quiet", "Quick") flag:

```bash
$ docker ps -q
068cc994ffd0
57ad9bdfc06b
47d677dcfba4
```

---

## Combining flags

We can combine `-l` and `-q` to see only the ID of the last container started:

```bash
$ docker ps -lq
068cc994ffd0
```

At a first glance, it looks like this would be particularly useful in scripts.

However, if we want to start a container and get its ID in a reliable way,
it is better to use `docker run -d`, which we will cover in a bit.

(Using `docker ps -lq` is prone to race conditions: what happens if someone
else, or another program or script, starts another container just before
we run `docker ps -lq`?)

---

## View the logs of a container

We told you that Docker was logging the container output.

Let's see that now.

```bash
$ docker logs 068
Fri Feb 20 00:39:52 UTC 2015
Fri Feb 20 00:39:53 UTC 2015
...
```

* We specified a *prefix* of the full container ID.
* You can, of course, specify the full ID.
* The `logs` command will output the *entire* logs of the container.
  <br/>(Sometimes, that will be too much. Let's see how to address that.)

---

## View only the tail of the logs

To avoid being spammed with eleventy pages of output,
we can use the `--tail` option:

```bash
$ docker logs --tail 3 068
Fri Feb 20 00:55:35 UTC 2015
Fri Feb 20 00:55:36 UTC 2015
Fri Feb 20 00:55:37 UTC 2015
```

* The parameter is the number of lines that we want to see.

---

## Follow the logs in real time

Just like with the standard UNIX command `tail -f`, we can
follow the logs of our container:

```bash
$ docker logs --tail 1 --follow 068
Fri Feb 20 00:57:12 UTC 2015
Fri Feb 20 00:57:13 UTC 2015
^C
```

* This will display the last line in the log file.
* Then, it will continue to display the logs in real time.
* Use `^C` to exit.

---

## Stop our container

There are two ways we can terminate our detached container.

* Killing it using the `docker kill` command.
* Stopping it using the `docker stop` command.

The first one stops the container immediately, by using the
`KILL` signal.

The second one is more graceful. It sends a `TERM` signal,
and after 10 seconds, if the container has not stopped, it
sends `KILL.`

Reminder: the `KILL` signal cannot be intercepted, and will
forcibly terminate the container.

---

## Stopping our containers

Let's stop one of those containers:

```bash
$ docker stop 47d6
47d6
```

This will take 10 seconds:

* Docker sends the TERM signal;
* the container doesn't react to this signal
  (it's a simple Shell script with no special
  signal handling);
* 10 seconds later, since the container is still
  running, Docker sends the KILL signal;
* this terminates the container.

---

## Killing the remaining containers

Let's be less patient with the two other containers:

```bash
$ docker kill 068 57ad
068
57ad
```

The `stop` and `kill` commands can take multiple container IDs.

Those containers will be terminated immediately (without
the 10-second delay).

Let's check that our containers don't show up anymore:

```bash
$ docker ps
```

---

## List stopped containers

We can also see stopped containers, with the `-a` (`--all`) option.

```bash
$ docker ps -a
CONTAINER ID  IMAGE           ...  CREATED      STATUS
068cc994ffd0  jpetazzo/clock  ...  21 min. ago  Exited (137) 3 min. ago
57ad9bdfc06b  jpetazzo/clock  ...  21 min. ago  Exited (137) 3 min. ago
47d677dcfba4  jpetazzo/clock  ...  23 min. ago  Exited (137) 3 min. ago
5c1dfd4d81f1  jpetazzo/clock  ...  40 min. ago  Exited (0) 40 min. ago
b13c164401fb  ubuntu          ...  55 min. ago  Exited (130) 53 min. ago
```

???

:EN:- Foreground and background containers
:FR:- Exécution interactive ou en arrière-plan
