class: extra-details

## Troubleshooting overlay networks

<!--

## Finding the real cause of the bottleneck

- We want to debug our app as we scale `worker` up and down

-->

- We want to run tools like `ab` or `httping` on the internal network

--

class: extra-details

- Ah, if only we had created our overlay network with the `--attachable` flag ...

--

class: extra-details

- Oh well, let's use this as an excuse to introduce New Ways To Do Things

---

# Breaking into an overlay network

- We will create a dummy placeholder service on our network

- Then we will use `docker exec` to run more processes in this container

.lab[

- Start a "do nothing" container using our favorite Swiss-Army distro:
  ```bash
    docker service create --network dockercoins_default --name debug \
           --constraint node.hostname==$HOSTNAME alpine sleep 1000000000
  ```

]

The `constraint` makes sure that the container will be created on the local node.

---

## Entering the debug container

- Once our container is started (which should be really fast because the alpine image is small), we can enter it (from any node)

.lab[

- Locate the container:
  ```bash
  docker ps
  ```

- Enter it:
  ```bash
  docker exec -ti containerID sh
  ```

  <!-- ```wait No such container: containerID``` -->

]

---

## Labels

- We can also be fancy and find the ID of the container automatically

- SwarmKit places labels on containers

.lab[

- Get the ID of the container:
  ```bash
  CID=$(docker ps -q --filter label=com.docker.swarm.service.name=debug)
  ```

- And enter the container:
  ```bash
  docker exec -ti $CID sh
  ```

]

---

## Installing our debugging tools

- Ideally, you would author your own image, with all your favorite tools, and use it instead of the base `alpine` image

- But we can also dynamically install whatever we need

.lab[

- Install a few tools:
  ```bash
  apk add --update curl apache2-utils drill
  ```

]

---

## Investigating the `rng` service

- First, let's check what `rng` resolves to

.lab[

- Use drill or nslookup to resolve `rng`:
  ```bash
  drill rng
  ```

]

This give us one IP address. It is not the IP address of a container.
It is a virtual IP address (VIP) for the `rng` service.

---

## Investigating the VIP

.lab[

- Try to ping the VIP:
  ```bash
  ping -c 3 rng
  ```

]

It *should* ping. (But this might change in the future.)

With Engine 1.12: VIPs respond to ping if a
backend is available on the same machine.

With Engine 1.13: VIPs respond to ping if a
backend is available anywhere.

(Again: this might change in the future.)

---

## What if I don't like VIPs?

- Services can be published using two modes: VIP and DNSRR.

- With VIP, you get a virtual IP for the service, and a load balancer
  based on IPVS

  (By the way, IPVS is totally awesome and if you want to learn more about it in the context of containers,
  I highly recommend [this talk](https://www.youtube.com/watch?v=oFsJVV1btDU&index=5&list=PLkA60AVN3hh87OoVra6MHf2L4UR9xwJkv) by [@kobolog](https://twitter.com/kobolog) at DC15EU!)

- With DNSRR, you get the former behavior (from Engine 1.11), where
  resolving the service yields the IP addresses of all the containers for
  this service

- You change this with `docker service create --endpoint-mode [VIP|DNSRR]`

---

## Looking up VIP backends

- You can also resolve a special name: `tasks.<name>`

- It will give you the IP addresses of the containers for a given service

.lab[

- Obtain the IP addresses of the containers for the `rng` service:
  ```bash
  drill tasks.rng
  ```

]

This should list 5 IP addresses.

---

class: extra-details, benchmarking

## Testing and benchmarking our service

- We will check that the service is up with `rng`, then
  benchmark it with `ab`

.lab[

- Make a test request to the service:
  ```bash
  curl rng
  ```

- Open another window, and stop the workers, to test in isolation:
  ```bash
  docker service update dockercoins_worker --replicas 0
  ```

]

Wait until the workers are stopped (check with `docker service ls`)
before continuing.

---

class: extra-details, benchmarking

## Benchmarking `rng`

We will send 50 requests, but with various levels of concurrency.

.lab[

- Send 50 requests, with a single sequential client:
  ```bash
  ab -c 1 -n 50 http://rng/10
  ```

- Send 50 requests, with fifty parallel clients:
  ```bash
  ab -c 50 -n 50 http://rng/10
  ```

]

---

class: extra-details, benchmarking

## Benchmark results for `rng`

- When serving requests sequentially, they each take 100ms

- In the parallel scenario, the latency increased dramatically:

- What about `hasher`?

---

class: extra-details, benchmarking

## Benchmarking `hasher`

We will do the same tests for `hasher`.

The command is slightly more complex, since we need to post random data.

First, we need to put the POST payload in a temporary file.

.lab[

- Generate 10 bytes of random data:
  ```bash
  curl http://rng/10 >/tmp/random
  ```

]

---

class: extra-details, benchmarking

## Benchmarking `hasher`

Once again, we will send 50 requests, with different levels of concurrency.

.lab[

- Send 50 requests with a sequential client:
  ```bash
    ab -c 1 -n 50 -T application/octet-stream -p /tmp/random http://hasher/
  ```

- Send 50 requests with 50 parallel clients:
  ```bash
    ab -c 50 -n 50 -T application/octet-stream -p /tmp/random http://hasher/
  ```

<!-- ```bash exit``` -->

]

---

class: extra-details, benchmarking

## Benchmark results for `hasher`

- The sequential benchmarks takes ~5 seconds to complete

- The parallel benchmark takes less than 1 second to complete

- In both cases, each request takes a bit more than 100ms to complete

- Requests are a bit slower in the parallel benchmark

- It looks like `hasher` is better equipped to deal with concurrency than `rng`

---

class: extra-details, title, benchmarking

Why?

---

class: extra-details, benchmarking

## Why does everything take (at least) 100ms?

`rng` code:

![RNG code screenshot](images/delay-rng.png)

`hasher` code:

![HASHER code screenshot](images/delay-hasher.png)

---

class: extra-details, title, benchmarking

But ...

WHY?!?

---

class: extra-details, benchmarking

## Why did we sprinkle the code with sleeps?

- Deterministic performance
  <br/>(regardless of instance speed, CPUs, I/O...)

- Actual code sleeps all the time anyway

- When your code makes a remote API call:

  - it sends a request;

  - it sleeps until it gets the response;

  - it processes the response.

---

class: extra-details, in-person, benchmarking

## Why do `rng` and `hasher` behave differently?

![Equations on a blackboard](images/equations.png)

(Synchronous vs. asynchronous event processing)

---

class: extra-details

## Global scheduling → global debugging

- Traditional approach:

  - log into a node
  - install our Swiss Army Knife (if necessary)
  - troubleshoot things

- Proposed alternative:

  - put our Swiss Army Knife in a container (e.g. [nicolaka/netshoot](https://hub.docker.com/r/nicolaka/netshoot/))
  - run tests from multiple locations at the same time

(This becomes very practical with the `docker service log` command, available since 17.05.)

---

## More about overlay networks

.blackbelt[DC17US: Deep Dive in Docker Overlay Networks ([video](https://www.youtube.com/watch?v=b3XDl0YsVsg&index=1&list=PLkA60AVN3hh-biQ6SCtBJ-WVTyBmmYho8))]

.blackbelt[DC17EU: Deeper Dive in Docker Overlay Networks ([video](https://dockercon.docker.com/watch/XkRRA7Etsznv7uAk1UKsri))]
