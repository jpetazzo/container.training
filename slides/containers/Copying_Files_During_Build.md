
class: title

# Copying files during the build

![Monks copying books](images/title-copying-files-during-build.jpg)

---

## Objectives

So far, we have installed things in our container images
by downloading packages.

We can also copy files from the *build context* to the
container that we are building.

Remember: the *build context* is the directory containing
the Dockerfile.

In this chapter, we will learn a new Dockerfile keyword: `COPY`.

---

## Build some C code

We want to build a container that compiles a basic "Hello world" program in C.

Here is the program, `hello.c`:

```bash
int main () {
  puts("Hello, world!");
  return 0;
}
```

Let's create a new directory, and put this file in there.

Then we will write the Dockerfile.

---

## The Dockerfile

On Debian and Ubuntu, the package `build-essential` will get us a compiler.

When installing it, don't forget to specify the `-y` flag, otherwise the build will fail (since the build cannot be interactive).

Then we will use `COPY` to place the source file into the container.

```bash
FROM ubuntu
RUN apt-get update
RUN apt-get install -y build-essential
COPY hello.c /
RUN make hello
CMD /hello
```

Create this Dockerfile.

---

## Testing our C program

* Create `hello.c` and `Dockerfile` in the same directory.

* Run `docker build -t hello .` in this directory.

* Run `docker run hello`, you should see `Hello, world!`.

Success!

---

## `COPY` and the build cache

* Run the build again.

* Now, modify `hello.c` and run the build again.

* Docker can cache steps involving `COPY`.

* Those steps will not be executed again if the files haven't been changed.

---

## Details

* We can `COPY` whole directories recursively

* It is possible to do e.g. `COPY . .`

  (but it might require some extra precautions to avoid copying too much)
 
* In older Dockerfiles, you might see the `ADD` command; consider it deprecated

  (it is similar to `COPY` but can automatically extract archives)

* If we really wanted to compile C code in a container, we would:

  * place it in a different directory, with the `WORKDIR` instruction

  * even better, use the `gcc` official image

---

class: extra-details

## `.dockerignore`

- We can create a file named `.dockerignore`

  (at the top-level of the build context)

- It can contain file names and globs to ignore

- They won't be sent to the builder

  (and won't end up in the resulting image)

- See the [documentation] for the little details

  (exceptions can be made with `!`, multiple directory levels with `**`...)

[documentation]: https://docs.docker.com/engine/reference/builder/#dockerignore-file

???

:EN:- Leveraging the build cache for faster builds
:FR:- Tirer parti du cache afin d'optimiser la vitesse de *build*
