# Our sample application

- We will clone the GitHub repository onto our `node1`

- The repository also contains scripts and tools that we will use through the workshop

.lab[

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

## Downloading and running the application

Let's start this before we look around, as downloading will take a little time...

.lab[

- Go to the `dockercoins` directory, in the cloned repository:
  ```bash
  cd ~/container.training/dockercoins
  ```

- Use Compose to build and run all containers:
  ```bash
  docker-compose up
  ```

<!--
```longwait units of work done```
-->

]

Compose tells Docker to build all container images (pulling
the corresponding base images), then starts all containers,
and displays aggregated logs.

---

## What's this application?

--

- It is a DockerCoin miner! 💰🐳📦🚢

--

- No, you can't buy coffee with DockerCoin

--

- How dockercoins works:

  - generate a few random bytes

  - hash these bytes

  - increment a counter (to keep track of speed)

  - repeat forever!

--

- DockerCoin is *not* a cryptocurrency

  (the only common points are "randomness," "hashing," and "coins" in the name)

---

## DockerCoin in the microservices era

- The dockercoins app is made of 5 services:

  - `rng` = web service generating random bytes

  - `hasher` = web service computing hash of POSTed data

  - `worker` = background process calling `rng` and `hasher`

  - `webui` = web interface to watch progress

  - `redis` = data store (holds a counter updated by `worker`)

- These 5 services are visible in the application's Compose file,
  [docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml)

---

## How dockercoins works

- `worker` invokes web service `rng` to generate random bytes

- `worker` invokes web service `hasher` to hash these bytes

- `worker` does this in an infinite loop

- every second, `worker` updates `redis` to indicate how many loops were done

- `webui` queries `redis`, and computes and exposes "hashing speed" in our browser

*(See diagram on next slide!)*

---

class: pic

![Diagram showing the 5 containers of the applications](images/dockercoins-diagram.png)

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

class: extra-details

## Links, naming, and service discovery

- Containers can have network aliases (resolvable through DNS)

- Compose file version 2+ makes each container reachable through its service name

- Compose file version 1 required "links" sections to accomplish this

- Network aliases are automatically namespaced

  - you can have multiple apps declaring and using a service named `database`

  - containers in the blue app will resolve `database` to the IP of the blue database

  - containers in the green app will resolve `database` to the IP of the green database

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

class: extra-details

## Compose file format version

*This is relevant only if you have used Compose before 2016...*

- Compose 1.6 introduced support for a new Compose file format (aka "v2")

- Services are no longer at the top level, but under a `services` section

- There has to be a `version` key at the top level, with value `"2"` (as a string, not an integer)

- Containers are placed on a dedicated network, making links unnecessary

- There are other minor differences, but upgrade is easy and straightforward

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

.lab[

- With a web browser, connect to `node1` on port 8000

- Remember: the `nodeX` aliases are valid only on the nodes themselves

- In your browser, you need to enter the IP address of your node

<!-- ```open http://node1:8000``` -->

]

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

---

class: extra-details

## Why does the speed seem irregular?

- It *looks like* the speed is approximately 4 hashes/second

- Or more precisely: 4 hashes/second, with regular dips down to zero

- Why?

--

class: extra-details

- The app actually has a constant, steady speed: 3.33 hashes/second
  <br/>
  (which corresponds to 1 hash every 0.3 seconds, for *reasons*)

- Yes, and?

---

class: extra-details

## The reason why this graph is *not awesome*

- The worker doesn't update the counter after every loop, but up to once per second

- The speed is computed by the browser, checking the counter about once per second

- Between two consecutive updates, the counter will increase either by 4, or by 0

- The perceived speed will therefore be 4 - 4 - 4 - 0 - 4 - 4 - 0 etc.

- What can we conclude from this?

--

class: extra-details

- "I'm clearly incapable of writing good frontend code!" 😀 — Jérôme

---

## Stopping the application

- If we interrupt Compose (with `^C`), it will politely ask the Docker Engine to stop the app

- The Docker Engine will send a `TERM` signal to the containers

- If the containers do not exit in a timely manner, the Engine sends a `KILL` signal

.lab[

- Stop the application by hitting `^C`

<!--
```key ^C```
-->

]

--

Some containers exit immediately, others take longer.

The containers that do not handle `SIGTERM` end up being killed after a 10s timeout. If we are very impatient, we can hit `^C` a second time!

