# Our demo apps

- We are going to use a few demo apps for demos and labs

- Let's get acquainted with them before we dive in!

---

## The `color` app

- Image name: `jpetazzo/color`, `ghcr.io/jpetazzo/color`

- Available for linux/amd64, linux/arm64, linux/arm/v7 platforms

- HTTP server listening on port 80

- Serves a web page with a single line of text

- The background of the page is derived from the hostname

  (e.g. if the hostname is `blue-xyz-123`, the background is `blue`)

- The web page is "curl-friendly"

  (it contains `\r` characters to hide HTML tags and declutter the output)

---

## The `color` app in action

- Create a Deployment called `blue` using image `jpetazzo/color`

- Expose that Deployment with a Service

- Connect to the Service with a web browser

- Connect to the Service with `curl`

---

## Dockercoins

- App with 5 microservices:

  - `worker` (runs an infinite loop connecting to the other services)

  - `rng` (web service; generates random numbers)

  - `hasher` (web service; computes SHA sums)

  - `redis` (holds a single counter incremented by the `worker` at each loop)

  - `webui` (web app; displays a graph showing the rate of increase of the counter)

- Uses a mix of Node, Python, Ruby

- Very simple components (approx. 50 lines of code for the most complicated one)

---

class: pic

![Dockercoins application diagram](images/dockercoins-diagram.png)

---

## Deploying Dockercoins

- Pre-built images available as `dockercoins/<component>:v0.1`

  (e.g. `dockercoins/worker:v0.1`)

- Containers "discover" each other through DNS

  (e.g. worker connects to `http://hasher/`)

- A Kubernetes YAML manifest is available in *the* repo

---

## The repository

- When we refer to "the" repository, it means:

  https://github.com/jpetazzo/container.training

- It hosts slides, demo apps, deployment scripts...

- All the sample commands, labs, etc. will assume that it's available in:

  `~/container.training`

- Let's clone the repo in our environment!

---

## Cloning the repo

.lab[

- There is a convenient shortcut to clone the repository:
  ```bash
  git clone https://container.training
  ```

]

While the repository clones, fork it, star it ~~subscribe and hit the bell!~~

---

## Running Dockercoins

- All the Kubernetes manifests are in the `k8s` subdirectory

- This directory has a `dockercoins.yaml` manifest

.lab[

- Deploy Dockercoins:
  ```bash
  kubectl apply -f ~/container.training/k8s/dockercoins.yaml
  ```

]

- The `webui` is exposed with a `NodePort` service

- Connect to it (through the `NodePort` or `port-forward`)

- Note, it might take a minute for the worker to start

---

## Details

- If the `worker` Deployment is scaled up, the graph should go up

- The `rng` Service is meant to be a bottleneck

  (capping the graph to 10/second until `rng` is scaled up)

- There is artificial latency in the different services

  (so that the app doesn't consume CPU/RAM/network)

---

## More colors

- The repository also contains a `rainbow.yaml` manifest

- It creates three namespaces (`blue`, `green`, `red`)

- In each namespace, there is an instance of the `color` app

  (we can use that later to do *literal* blue-green deployment!)
