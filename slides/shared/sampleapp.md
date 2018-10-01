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

## Downloading and running the application

Let's start this before we look around, as downloading will take a little time...

.exercise[

- Go to the `dockercoins` directory, in the cloned repo:
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

## More detail on our sample application

- Visit the GitHub repository with all the materials of this workshop:
  <br/>https://@@GITREPO@@

- The application is in the [dockercoins](
  https://@@GITREPO@@/tree/master/dockercoins)
  subdirectory

- Let's look at the general layout of the source code:

  there is a Compose file [docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml) ...

  ... and 4 other services, each in its own directory:

  - `rng` = web service generating random bytes
  - `hasher` = web service computing hash of POSTed data
  - `worker` = background process using `rng` and `hasher`
  - `webui` = web interface to watch progress

---

## What's this application?

--

- It is a DockerCoin miner! .emoji[💰🐳📦🚢]

--

- No, you can't buy coffee with DockerCoins

--

- How DockerCoins works:

  - `worker` asks to `rng` to generate a few random bytes

  - `worker` feeds these bytes into `hasher`

  - and repeat forever!

  - every second, `worker` updates `redis` to indicate how many loops were done

  - `webui` queries `redis`, and computes and exposes "hashing speed" in your browser

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

.exercise[

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
work on a local environment, or when using Docker4Mac or Docker4Windows.

How to fix this?

Stop the app with `^C`, edit `dockercoins.yml`, comment out the `volumes` section, and try again.

---

## Stopping the application

- If we interrupt Compose (with `^C`), it will politely ask the Docker Engine to stop the app

- The Docker Engine will send a `TERM` signal to the containers

- If the containers do not exit in a timely manner, the Engine sends a `KILL` signal

.exercise[

- Stop the application by hitting `^C`

<!--
```keys ^C```
-->

]

--

Some containers exit immediately, others take longer.

The containers that do not handle `SIGTERM` end up being killed after a 10s timeout. If we are very impatient, we can hit `^C` a second time!

