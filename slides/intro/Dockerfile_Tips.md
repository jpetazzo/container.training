# Tips for efficient Dockerfiles

We will see how to:

* Reduce the number of layers.

* Leverage the build cache so that builds can be faster.

* Embed unit testing in the build process.

---

## Reducing the number of layers

* Each line in a `Dockerfile` creates a new layer.

* Build your `Dockerfile` to take advantage of Docker's caching system.

* Combine commands by using `&&` to continue commands and `\` to wrap lines.

Note: it is frequent to build a Dockerfile line by line:

```dockerfile
RUN apt-get install thisthing
RUN apt-get install andthatthing andthatotherone
RUN apt-get install somemorestuff
```

And then refactor it trivially before shipping:

```dockerfile
RUN apt-get install thisthing andthatthing andthatotherone somemorestuff
```

---

## Avoid re-installing dependencies at each build

* Classic Dockerfile problem:

  "each time I change a line of code, all my dependencies are re-installed!"

* Solution: `COPY` dependency lists (`package.json`, `requirements.txt`, etc.)
  by themselves to avoid reinstalling unchanged dependencies every time.

---

## Example "bad" `Dockerfile`

The dependencies are reinstalled every time, because the build system does not know if `requirements.txt` has been updated.

```bash
FROM python
MAINTAINER Docker Education Team <education@docker.com>
COPY . /src/
WORKDIR /src
RUN pip install -qr requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
```

---

## Fixed `Dockerfile`

Adding the dependencies as a separate step means that Docker can cache more efficiently and only install them when `requirements.txt` changes.

```bash
FROM python
MAINTAINER Docker Education Team <education@docker.com>
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install -qr /tmp/requirements.txt
COPY . /src/
WORKDIR /src
EXPOSE 5000
CMD ["python", "app.py"]
```

---

## Embedding unit tests in the build process

```dockerfile
FROM <baseimage>
RUN <install dependencies>
COPY <code>
RUN <build code>
RUN <install test dependencies>
COPY <test data sets and fixtures>
RUN <unit tests>
FROM <baseimage>
RUN <install dependencies>
COPY <vcode>
RUN <build code>
CMD, EXPOSE ...
```

* The build fails as soon as an instructions fails
* If `RUN <unit tests>` fails, the build doesn't produce an image
* If it succeeds, it produces a clean image (without test libraries and data)
