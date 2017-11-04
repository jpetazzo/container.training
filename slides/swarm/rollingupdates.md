# Rolling updates

- Let's change a scaled service: `worker`

.exercise[

- Edit `worker/worker.py`

- Locate the `sleep` instruction and change the delay

- Build, ship, and run our changes:
  ```bash
  export TAG=v0.4
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  docker stack deploy -c dockercoins.yml dockercoins
  ```

]

---

## Viewing our update as it rolls out

.exercise[

- Check the status of the `dockercoins_worker` service:
  ```bash
  watch docker service ps dockercoins_worker
  ```

- Hide the tasks that are shutdown:
  ```bash
  watch -n1 "docker service ps dockercoins_worker | grep -v Shutdown.*Shutdown"
  ```

]

If you had stopped the workers earlier, this will automatically restart them.

By default, SwarmKit does a rolling upgrade, one instance at a time.

We should therefore see the workers being updated one my one.

---

## Changing the upgrade policy

- We can set upgrade parallelism (how many instances to update at the same time)

- And upgrade delay (how long to wait between two batches of instances)

.exercise[

- Change the parallelism to 2 and the delay to 5 seconds:
  ```bash
    docker service update dockercoins_worker \
      --update-parallelism 2 --update-delay 5s
  ```

]

The current upgrade will continue at a faster pace.

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

  - by editing the Compose file and redeploying;

  - or with the special `--rollback` flag

.exercise[

- Try to rollback the service:
  ```bash
  docker service update dockercoins_worker --rollback
  ```

]

What happens with the web UI graph?

---

## The fine print with rollback

- Rollback reverts to the previous service definition

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
