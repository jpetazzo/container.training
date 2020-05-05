
class: title

# Naming and inspecting containers

![Markings on container door](images/title-naming-and-inspecting-containers.jpg)

---

## Objectives

In this lesson, we will learn about an important
Docker concept: container *naming*.

Naming allows us to:

* Reference easily a container.

* Ensure unicity of a specific container.

We will also see the `inspect` command, which gives a lot of details about a container.

---

## Naming our containers

So far, we have referenced containers with their ID.

We have copy-pasted the ID, or used a shortened prefix.

But each container can also be referenced by its name.

If a container is named `thumbnail-worker`, I can do:

```bash
$ docker logs thumbnail-worker
$ docker stop thumbnail-worker
etc.
```

---

## Default names

When we create a container, if we don't give a specific
name, Docker will pick one for us.

It will be the concatenation of:

* A mood (furious, goofy, suspicious, boring...)

* The name of a famous inventor (tesla, darwin, wozniak...)

Examples: `happy_curie`, `clever_hopper`, `jovial_lovelace` ...

---

## Specifying a name

You can set the name of the container when you create it.

```bash
$ docker run --name ticktock jpetazzo/clock
```

If you specify a name that already exists, Docker will refuse
to create the container.

This lets us enforce unicity of a given resource.

---

## Renaming containers

* You can rename containers with `docker rename`.

* This allows you to "free up" a name without destroying the associated container.

---

## Inspecting a container

The `docker inspect` command will output a very detailed JSON map.

```bash
$ docker inspect <containerID>
[{
...
(many pages of JSON here)
...
```

There are multiple ways to consume that information.

---

## Parsing JSON with the Shell

* You *could* grep and cut or awk the output of `docker inspect`.

* Please, don't.

* It's painful.

* If you really must parse JSON from the Shell, use JQ! (It's great.)

```bash
$ docker inspect <containerID> | jq .
```

* We will see a better solution which doesn't require extra tools.

---

## Using `--format`

You can specify a format string, which will be parsed by 
Go's text/template package.

```bash
$ docker inspect --format '{{ json .Created }}' <containerID>
"2015-02-24T07:21:11.712240394Z"
```

* The generic syntax is to wrap the expression with double curly braces.

* The expression starts with a dot representing the JSON object.

* Then each field or member can be accessed in dotted notation syntax.

* The optional `json` keyword asks for valid JSON output.
  <br/>(e.g. here it adds the surrounding double-quotes.)

???

:EN:Managing container lifecycle
:EN:- Naming and inspecting containers

:FR:Suivre ses conteneurs à la loupe
:FR:- Obtenir des informations détaillées sur un conteneur
:FR:- Associer un identifiant unique à un conteneur
