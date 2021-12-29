name: healthchecks

# Health checks and auto-rollbacks

(New in Docker Engine 1.12)

- Commands that are executed on regular intervals in a container

- Must return 0 or 1 to indicate "all is good" or "something's wrong"

- Must execute quickly (timeouts = failures)

- Example:
  ```bash
  curl -f http://localhost/_ping || false
  ```
  - the `-f` flag ensures that `curl` returns non-zero for 404 and similar errors
  - `|| false` ensures that any non-zero exit status gets mapped to 1
  - `curl` must be installed in the container that is being checked

---

## Defining health checks

- In a Dockerfile, with the [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck) instruction
  ```
  HEALTHCHECK --interval=1s --timeout=3s CMD curl -f http://localhost/ || false
  ```

- From the command line, when running containers or services
  ```
  docker run --health-cmd "curl -f http://localhost/ || false" ...
  docker service create --health-cmd "curl -f http://localhost/ || false" ...
  ```

- In Compose files, with a per-service [healthcheck](https://docs.docker.com/compose/compose-file/#healthcheck) section
  ```yaml
    www:
      image: hellowebapp
      healthcheck:
        test: "curl -f https://localhost/ || false"
        timeout: 3s
  ```

---

## Using health checks

- With `docker run`, health checks are purely informative

  - `docker ps` shows health status

  - `docker inspect` has extra details (including health check command output)

- With `docker service`:

  - unhealthy tasks are terminated (i.e. the service is restarted)

  - failed deployments can be rolled back automatically
    <br/>(by setting *at least* the flag `--update-failure-action rollback`)

---

## Enabling health checks and auto-rollbacks

Here is a comprehensive example using the CLI:

.small[
```bash
docker service update \
  --update-delay 5s \
  --update-failure-action rollback \
  --update-max-failure-ratio .25 \
  --update-monitor 5s \
  --update-parallelism 1 \
  --rollback-delay 5s \
  --rollback-failure-action pause \
  --rollback-max-failure-ratio .5 \
  --rollback-monitor 5s \
  --rollback-parallelism 0 \
  --health-cmd "curl -f http://localhost/ || exit 1" \
  --health-interval 2s \
  --health-retries 1 \
  --image yourimage:newversion yourservice
```
]

---

## Implementing auto-rollback in practice

We will use the following Compose file (`stacks/dockercoins+healthcheck.yml`):

```yaml
...
  hasher:
    build: dockercoins/hasher
    image: ${REGISTRY-127.0.0.1:5000}/hasher:${TAG-latest}
    healthcheck:
      test: curl -f http://localhost/ || exit 1
    deploy:
      replicas: 7
      update_config:
        delay: 5s
        failure_action: rollback
        max_failure_ratio: .5
        monitor: 5s
        parallelism: 1
...
```

---

## Enabling auto-rollback in dockercoins

We need to update our services with a healthcheck.

.lab[

- Go to the `stacks` directory:
  ```bash
  cd ~/container.training/stacks
  ```

- Deploy the updated stack with healthchecks built-in:
  ```bash
  docker stack deploy --compose-file dockercoins+healthcheck.yml dockercoins 
  ```

]

---

## Visualizing an automated rollback

- Here's a good example of why healthchecks are necessary

- This breaking change will prevent the app from listening on the correct port

- The container still runs fine, it just won't accept connections on port 80

.lab[

- Change the HTTP listening port:
  ```bash
  sed -i "s/80/81/" dockercoins/hasher/hasher.rb
  ```

- Build, ship, and run the new image:
  ```bash
  export TAG=v0.3
  docker-compose -f dockercoins+healthcheck.yml build
  docker-compose -f dockercoins+healthcheck.yml push
  docker service update --image=127.0.0.1:5000/hasher:$TAG dockercoins_hasher
  ```

]

---

## CLI flags for health checks and rollbacks

.small[
```
--health-cmd string                  Command to run to check health
--health-interval duration           Time between running the check (ms|s|m|h)
--health-retries int                 Consecutive failures needed to report unhealthy
--health-start-period duration       Start period for the container to initialize before counting retries towards unstable (ms|s|m|h)
--health-timeout duration            Maximum time to allow one check to run (ms|s|m|h)
--no-healthcheck                     Disable any container-specified HEALTHCHECK
--restart-condition string           Restart when condition is met ("none"|"on-failure"|"any")
--restart-delay duration             Delay between restart attempts (ns|us|ms|s|m|h)
--restart-max-attempts uint          Maximum number of restarts before giving up
--restart-window duration            Window used to evaluate the restart policy (ns|us|ms|s|m|h)
--rollback                           Rollback to previous specification
--rollback-delay duration            Delay between task rollbacks (ns|us|ms|s|m|h)
--rollback-failure-action string     Action on rollback failure ("pause"|"continue")
--rollback-max-failure-ratio float   Failure rate to tolerate during a rollback
--rollback-monitor duration          Duration after each task rollback to monitor for failure (ns|us|ms|s|m|h)
--rollback-order string              Rollback order ("start-first"|"stop-first")
--rollback-parallelism uint          Maximum number of tasks rolled back simultaneously (0 to roll back all at once)
--update-delay duration              Delay between updates (ns|us|ms|s|m|h)
--update-failure-action string       Action on update failure ("pause"|"continue"|"rollback")
--update-max-failure-ratio float     Failure rate to tolerate during an update
--update-monitor duration            Duration after each task update to monitor for failure (ns|us|ms|s|m|h)
--update-order string                Update order ("start-first"|"stop-first")
--update-parallelism uint            Maximum number of tasks updated simultaneously (0 to update all at once)
```
]
