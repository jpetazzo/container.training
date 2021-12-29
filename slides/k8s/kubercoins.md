# Deploying a sample application

- We will connect to our new Kubernetes cluster

- We will deploy a sample application, "DockerCoins"

- That app features multiple micro-services and a web UI

---

## Connecting to our Kubernetes cluster

- Our cluster has multiple nodes named `node1`, `node2`, etc.

- We will do everything from `node1`

- We have SSH access to the other nodes, but won't need it

  (but we can use it for debugging, troubleshooting, etc.)

.lab[

- Log into `node1`

- Check that all nodes are `Ready`:
  ```bash
  kubectl get nodes
  ```

]

---

## Cloning the repository

- We will need to clone the training repository

- It has the DockerCoins demo app ...

- ... as well as these slides, some scripts, more manifests

.lab[

- Clone the repository on `node1`:
  ```bash
  git clone https://@@GITREPO@@
  ```

]

---

## Running the application

Without further ado, let's start this application!

.lab[

- Apply the manifest for dockercoins:
  ```bash
  kubectl apply -f ~/container.training/k8s/dockercoins.yaml
  ```

]

---

## What's this application?

--

- It is a DockerCoin miner! 💰🐳📦🚢

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

  (the only common points are "randomness", "hashing", and "coins" in the name)

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

- We can check the logs of our application's pods

.lab[

- Check the logs of the various components:
  ```bash
  kubectl logs deploy/worker
  kubectl logs deploy/hasher
  ```

]

---

## Connecting to the web UI

- "Logs are exciting and fun!" (No-one, ever)

- The `webui` container exposes a web dashboard; let's view it

.lab[

- Check the NodePort allocated to the web UI:
  ```bash
  kubectl get svc webui
  ```

- Open that in a web browser

]

A drawing area should show up, and after a few seconds, a blue
graph will appear.

???

:EN:- Deploying a sample app with YAML manifests
:FR:- Lancer une application de démo avec du YAML
