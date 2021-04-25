
class: title

# `CMD` and `ENTRYPOINT`

![Container entry doors](images/entrypoint.jpg)

---

## Objectives

In this lesson, we will learn about two important
Dockerfile commands:

`CMD` and `ENTRYPOINT`.

These commands allow us to set the default command
to run in a container.

---

## Defining a default command

When people run our container, we want to greet them with a nice hello message, and using a custom font.

For that, we will execute:

```bash
figlet -f script hello
```

* `-f script` tells figlet to use a fancy font.

* `hello` is the message that we want it to display.

---

## Adding `CMD` to our Dockerfile

Our new Dockerfile will look like this:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
CMD figlet -f script hello
```

* `CMD` defines a default command to run when none is given.

* It can appear at any point in the file.

* Each `CMD` will replace and override the previous one.

* As a result, while you can have multiple `CMD` lines, it is useless.

---

## Build and test our image

Let's build it:

```bash
$ docker build -t figlet .
...
Successfully built 042dff3b4a8d
Successfully tagged figlet:latest
```

And run it:

```bash
$ docker run figlet
 _          _   _       
| |        | | | |      
| |     _  | | | |  __  
|/ \   |/  |/  |/  /  \_
|   |_/|__/|__/|__/\__/ 
```

---

## Overriding `CMD`

If we want to get a shell into our container (instead of running
`figlet`), we just have to specify a different program to run:

```bash
$ docker run -it figlet bash
root@7ac86a641116:/# 
```

* We specified `bash`.

* It replaced the value of `CMD`.

---

## Using `ENTRYPOINT`

We want to be able to specify a different message on the command line,
while retaining `figlet` and some default parameters.

In other words, we would like to be able to do this:

```bash
$ docker run figlet salut
           _            
          | |           
 ,   __,  | |       _|_ 
/ \_/  |  |/  |   |  |  
 \/ \_/|_/|__/ \_/|_/|_/
```


We will use the `ENTRYPOINT` verb in Dockerfile.

---

## Adding `ENTRYPOINT` to our Dockerfile

Our new Dockerfile will look like this:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
ENTRYPOINT ["figlet", "-f", "script"]
```

* `ENTRYPOINT` defines a base command (and its parameters) for the container.

* The command line arguments are appended to those parameters.

* Like `CMD`, `ENTRYPOINT` can appear anywhere, and replaces the previous value.

Why did we use JSON syntax for our `ENTRYPOINT`?

---

## Implications of JSON vs string syntax

* When CMD or ENTRYPOINT use string syntax, they get wrapped in `sh -c`.

* To avoid this wrapping, we can use JSON syntax.

What if we used `ENTRYPOINT` with string syntax?

```bash
$ docker run figlet salut
```

This would run the following command in the `figlet` image:

```bash
sh -c "figlet -f script" salut
```

---

## Build and test our image

Let's build it:

```bash
$ docker build -t figlet .
...
Successfully built 36f588918d73
Successfully tagged figlet:latest
```

And run it:

```bash
$ docker run figlet salut
           _            
          | |           
 ,   __,  | |       _|_ 
/ \_/  |  |/  |   |  |  
 \/ \_/|_/|__/ \_/|_/|_/
```

---

## Using `CMD` and `ENTRYPOINT` together

What if we want to define a default message for our container?

Then we will use `ENTRYPOINT` and `CMD` together.

* `ENTRYPOINT` will define the base command for our container.

* `CMD` will define the default parameter(s) for this command.

* They *both* have to use JSON syntax.

---

## `CMD` and `ENTRYPOINT` together

Our new Dockerfile will look like this:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
ENTRYPOINT ["figlet", "-f", "script"]
CMD ["hello world"]
```

* `ENTRYPOINT` defines a base command (and its parameters) for the container.

* If we don't specify extra command-line arguments when starting the container,
  the value of `CMD` is appended.

* Otherwise, our extra command-line arguments are used instead of `CMD`.

---

## Build and test our image

Let's build it:

```bash
$ docker build -t myfiglet .
...
Successfully built 6e0b6a048a07
Successfully tagged myfiglet:latest
```

Run it without parameters:

```bash
$ docker run myfiglet
 _          _   _                             _        
| |        | | | |                           | |    |  
| |     _  | | | |  __             __   ,_   | |  __|  
|/ \   |/  |/  |/  /  \_  |  |  |_/  \_/  |  |/  /  |  
|   |_/|__/|__/|__/\__/    \/ \/  \__/    |_/|__/\_/|_/
```

---

## Overriding the image default parameters

Now let's pass extra arguments to the image.

```bash
$ docker run myfiglet hola mundo
 _           _                                               
| |         | |                                      |       
| |     __  | |  __,     _  _  _           _  _    __|   __  
|/ \   /  \_|/  /  |    / |/ |/ |  |   |  / |/ |  /  |  /  \_
|   |_/\__/ |__/\_/|_/    |  |  |_/ \_/|_/  |  |_/\_/|_/\__/ 
```

We overrode `CMD` but still used `ENTRYPOINT`.

---

## Overriding `ENTRYPOINT`

What if we want to run a shell in our container?

We cannot just do `docker run myfiglet bash` because
that would just tell figlet to display the word "bash."

We use the `--entrypoint` parameter:

```bash
$ docker run -it --entrypoint bash myfiglet
root@6027e44e2955:/# 
```

---

## `CMD` and `ENTRYPOINT` recap

- `docker run myimage` executes `ENTRYPOINT` + `CMD`

- `docker run myimage args` executes `ENTRYPOINT` + `args` (overriding `CMD`)

- `docker run --entrypoint prog myimage` executes `prog` (overriding both)

.small[
| Command                         | `ENTRYPOINT`       | `CMD`   | Result
|---------------------------------|--------------------|---------|-------
| `docker run figlet`             | none               | none    | Use values from base image (`bash`)
| `docker run figlet hola`        | none               | none    | Error (executable `hola` not found)
| `docker run figlet`             | `figlet -f script` | none    | `figlet -f script`
| `docker run figlet hola`        | `figlet -f script` | none    | `figlet -f script hola`
| `docker run figlet`             | none    | `figlet -f script` | `figlet -f script`
| `docker run figlet hola`        | none    | `figlet -f script` | Error (executable `hola` not found)
| `docker run figlet`             | `figlet -f script` | `hello` | `figlet -f script hello`
| `docker run figlet hola`        | `figlet -f script` | `hello` | `figlet -f script hola`
]

---

## When to use `ENTRYPOINT` vs `CMD`

`ENTRYPOINT` is great for "containerized binaries".

Example: `docker run consul --help`

(Pretend that the `docker run` part isn't there!)

`CMD` is great for images with multiple binaries.

Example: `docker run busybox ifconfig`

(It makes sense to indicate *which* program we want to run!)

???

:EN:- CMD and ENTRYPOINT
:FR:- CMD et ENTRYPOINT
