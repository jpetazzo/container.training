# Rolling updates

- Let's force an update on hasher to watch it update

.lab[

- First lets scale up hasher to 7 replicas:
  ```bash
  docker service scale dockercoins_hasher=7
  ```

- Force a rolling update (replace containers) to different image:
  ```bash
  docker service update --image 127.0.0.1:5000/hasher:v0.1 dockercoins_hasher
  ```

]

- You can run `docker events` in a separate `node1` shell to see Swarm actions

- You can use `--force` to replace containers without a config change

---

## Changing the upgrade policy

- We can change many options on how updates happen

.lab[

- Change the parallelism to 2, and the max failed container updates to 25%:
  ```bash
    docker service update --update-parallelism 2 \
      --update-max-failure-ratio .25 dockercoins_hasher
  ```

]

- No containers were replaced, this is called a "no op" change 

- Service metadata-only changes don't require orchestrator operations

---

## Changing the policy in the Compose file

- The policy can also be updated in the Compose file

- This is done by adding an `update_config` key under the `deploy` key:

  ```yaml
    deploy:
      replicas: 10
      update_config:
        parallelism: 2
        delay: 10s
  ```

---

## Rolling back

- At any time (e.g. before the upgrade is complete), we can rollback:

  - by editing the Compose file and redeploying

  - by using the special `--rollback` flag with `service update`

  - by using `docker service rollback`

.lab[

- Try to rollback the webui service:
  ```bash
  docker service rollback dockercoins_webui
  ```

]

What happens with the web UI graph?

---

## The fine print with rollback

- Rollback reverts to the previous service definition

  - see `PreviousSpec` in `docker service inspect <servicename>`

- If we visualize successive updates as a stack:

  - it doesn't "pop" the latest update

  - it "pushes" a copy of the previous update on top

  - ergo, rolling back twice does nothing

- "Service definition" includes rollout cadence

- Each `docker service update` command = a new service definition

---

class: extra-details

## Timeline of an upgrade

- SwarmKit will upgrade N instances at a time
  <br/>(following the `update-parallelism` parameter)

- New tasks are created, and their desired state is set to `Ready`
  <br/>.small[(this pulls the image if necessary, ensures resource availability, creates the container ... without starting it)]

- If the new tasks fail to get to `Ready` state, go back to the previous step
  <br/>.small[(SwarmKit will try again and again, until the situation is addressed or desired state is updated)]

- When the new tasks are `Ready`, it sets the old tasks desired state to `Shutdown`

- When the old tasks are `Shutdown`, it starts the new tasks

- Then it waits for the `update-delay`, and continues with the next batch of instances
