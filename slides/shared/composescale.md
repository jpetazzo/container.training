## Restarting in the background

- Many flags and commands of Compose are modeled after those of `docker`

.exercise[

- Start the app in the background with the `-d` option:
  ```bash
  docker-compose up -d
  ```

- Check that our app is running with the `ps` command:
  ```bash
  docker-compose ps
  ```

]

`docker-compose ps` also shows the ports exposed by the application.

---

class: extra-details

## Viewing logs

- The `docker-compose logs` command works like `docker logs`

.exercise[

- View all logs since container creation and exit when done:
  ```bash
  docker-compose logs
  ```

- Stream container logs, starting at the last 10 lines for each container:
  ```bash
  docker-compose logs --tail 10 --follow
  ```

<!--
```wait units of work done```
```key ^C```
-->

]

Tip: use `^S` and `^Q` to pause/resume log output.

---

## Scaling up the application

- Our goal is to make that performance graph go up (without changing a line of code!)

--

- Before trying to scale the application, we'll figure out if we need more resources

  (CPU, RAM...)

- For that, we will use good old UNIX tools on our Docker node

---

## Looking at resource usage

- Let's look at CPU, memory, and I/O usage

.exercise[

- run `top` to see CPU and memory usage (you should see idle cycles)

<!--
```bash top```

```wait Tasks```
```key ^C```
-->

- run `vmstat 1` to see I/O usage (si/so/bi/bo)
  <br/>(the 4 numbers should be almost zero, except `bo` for logging)

<!--
```bash vmstat 1```

```wait memory```
```key ^C```
-->

]

We have available resources.

- Why?
- How can we use them?

---

## Scaling workers on a single node

- Docker Compose supports scaling
- Let's scale `worker` and see what happens!

.exercise[

- Start one more `worker` container:
  ```bash
  docker-compose up -d --scale worker=2
  ```

- Look at the performance graph (it should show a x2 improvement)

- Look at the aggregated logs of our containers (`worker_2` should show up)

- Look at the impact on CPU load with e.g. top (it should be negligible)

]

---

## Adding more workers

- Great, let's add more workers and call it a day, then!

.exercise[

- Start eight more `worker` containers:
  ```bash
  docker-compose up -d --scale worker=10
  ```

- Look at the performance graph: does it show a x10 improvement?

- Look at the aggregated logs of our containers

- Look at the impact on CPU load and memory usage

]

---

# Identifying bottlenecks

- You should have seen a 3x speed bump (not 10x)

- Adding workers didn't result in linear improvement

- *Something else* is slowing us down

--

- ... But what?

--

- The code doesn't have instrumentation

- Let's use state-of-the-art HTTP performance analysis!
  <br/>(i.e. good old tools like `ab`, `httping`...)

---

## Accessing internal services

- `rng` and `hasher` are exposed on ports 8001 and 8002

- This is declared in the Compose file:

  ```yaml
    ...
    rng:
      build: rng
      ports:
      - "8001:80"

    hasher:
      build: hasher
      ports:
      - "8002:80"
    ...
  ```

---

## Measuring latency under load

We will use `httping`.

.exercise[

- Check the latency of `rng`:
  ```bash
  httping -c 3 localhost:8001
  ```

- Check the latency of `hasher`:
  ```bash
  httping -c 3 localhost:8002
  ```

]

`rng` has a much higher latency than `hasher`.
