# Our sample application

- Visit the GitHub repository with all the materials of this workshop:
  <br/>https://github.com/jpetazzo/container.training

- The application is in the [dockercoins](
  https://github.com/jpetazzo/container.training/tree/master/dockercoins)
  subdirectory

- Let's look at the general layout of the source code:

  there is a Compose file [docker-compose.yml](
  https://github.com/jpetazzo/container.training/blob/master/dockercoins/docker-compose.yml) ...

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

## Getting the application source code

- We will clone the GitHub repository

- The repository also contains scripts and tools that we will use through the workshop

.exercise[

<!--
```bash
if [ -d container.training ]; then
  mv container.training container.training.$$
fi
```
-->

- Clone the repository on `node1`:
  ```bash
  git clone https://github.com/jpetazzo/container.training/
  ```

]

(You can also fork the repository on GitHub and clone your fork if you prefer that.)

---

# Running the application

Without further ado, let's start our application.

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
```keys ^C```
-->

]

Compose tells Docker to build all container images (pulling
the corresponding base images), then starts all containers,
and displays aggregated logs.

---

## Lots of logs

- The application continuously generates logs

- We can see the `worker` service making requests to `rng` and `hasher`

- Let's put that in the background

.exercise[

- Stop the application by hitting `^C`

]

- `^C` stops all containers by sending them the `TERM` signal

- Some containers exit immediately, others take longer
  <br/>(because they don't handle `SIGTERM` and end up being killed after a 10s timeout)

---

## Connecting to the web UI

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

## Clean up

- Before moving on, let's remove those containers

.exercise[

- Tell Compose to remove everything:
  ```bash
  docker-compose down
  ```

]
