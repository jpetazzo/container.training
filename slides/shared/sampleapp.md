# Our sample application

- We will clone the GitHub repository onto our `node1`

- The repository also contains scripts and tools that we will use through the workshop

.exercise[

<!--
```bash
cd ~
if [ -d container.training ]; then
  mv container.training container.training.$RANDOM
fi
```
-->

- Clone the repository on `node1`:
  ```bash
  git clone https://@@GITREPO@@
  ```

]

(You can also fork the repository on GitHub and clone your fork if you prefer that.)

---

## Having a look at the application

.exercise[

- Go to the `dockercoins` directory, in the cloned repo:
  ```bash
  cd ~/container.training/dockercoins
  ```

- Check the files and directories:
  ```bash
  tree
  ```

]

---

## Viewing the application

- Jérôme is going to wear his developer hat ...

- ... start the application on his developer's machine ...

- ... and wait for the app to be up and running.

---

## What's this application?

--

- It is a DockerCoin miner! .emoji[💰🐳📦🚢]

--

- No, you can't buy coffee with DockerCoins

--

- How DockerCoins works:

  - generate a few random bytes

  - hash these bytes

  - increment a counter (to keep track of speed)

  - repeat forever!

--

- DockerCoins is *not* a cryptocurrency

  (the only common points are "randomness," "hashing," and "coins" in the name)

---

## DockerCoins in the microservices era

- DockerCoins is made of 5 services:

  - `rng` = web service generating random bytes

  - `hasher` = web service computing hash of POSTed data

  - `worker` = background process calling `rng` and `hasher`

  - `webui` = web interface to watch progress

  - `redis` = data store (holds a counter updated by `worker`)

- These 5 services are visible in the application's Compose file,
  [docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml)

---

## How DockerCoins works

- `worker` invokes web service `rng` to generate random bytes

- `worker` invokes web service `hasher` to hash these bytes

- `worker` does this in an infinite loop

- every second, `worker` updates `redis` to indicate how many loops were done

- `webui` queries `redis`, and computes and exposes "hashing speed" in our browser

*(See diagram on next slide!)*

---

class: pic

![Diagram showing the 5 containers of the applications](images/dockercoins-diagram.svg)

---

## Service discovery in container-land

How does each service find out the address of the other ones?

--

- We do not hard-code IP addresses in the code

- We do not hard-code FQDNs in the code, either

- We just connect to a service name, and container-magic does the rest

  (And by container-magic, we mean "a crafty, dynamic, embedded DNS server")

---

## Example in `worker/worker.py`

```python
redis = Redis("`redis`")


def get_random_bytes():
    r = requests.get("http://`rng`/32")
    return r.content


def hash_bytes(data):
    r = requests.post("http://`hasher`/",
                      data=data,
                      headers={"Content-Type": "application/octet-stream"})
```

(Full source code available [here](
https://@@GITREPO@@/blob/8279a3bce9398f7c1a53bdd95187c53eda4e6435/dockercoins/worker/worker.py#L17
))

---

## Show me the code!

- You can check the GitHub repository with all the materials of this workshop:
  <br/>https://@@GITREPO@@

- The application is in the [dockercoins](
  https://@@GITREPO@@/tree/master/dockercoins)
  subdirectory

- The Compose file ([docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml))
  lists all 5 services

- `redis` is using an official image from the Docker Hub

- `hasher`, `rng`, `worker`, `webui` are each built from a Dockerfile

- Each service's Dockerfile and source code is in its own directory

  (`hasher` is in the [hasher](https://@@GITREPO@@/blob/master/dockercoins/hasher/) directory,
  `rng` is in the [rng](https://@@GITREPO@@/blob/master/dockercoins/rng/)
  directory, etc.)

---

## Our application at work

- On the left-hand side, the "rainbow strip" shows the container names

- On the right-hand side, we see the output of our containers

- We can see the `worker` service making requests to `rng` and `hasher`

- For `rng` and `hasher`, we see HTTP access logs

---

## Connecting to the web UI

- "Logs are exciting and fun!" (No-one, ever)

- The `webui` container exposes a web dashboard; let's view it

A drawing area should show up, and after a few seconds, a blue
graph will appear.

---

class: self-paced, extra-details

## If the graph doesn't load

If you just see a `Page not found` error, it might be because your
Docker Engine is running on a different machine. This can be the case if:

- you are using the Docker Toolbox

- you are using a VM (local or remote) created with Docker Machine

- you are controlling a remote Docker Engine

When you run DockerCoins in development mode, the web UI static files
are mapped to the container using a volume. Alas, volumes can only
work on a local environment, or when using Docker Desktop for Mac or Windows.

How to fix this?

Stop the app with `^C`, edit `dockercoins.yml`, comment out the `volumes` section, and try again.
