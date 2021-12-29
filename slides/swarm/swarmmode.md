# Swarm mode

- Since version 1.12, the Docker Engine embeds SwarmKit

- All the SwarmKit features are "asleep" until you enable "Swarm mode"

- Examples of Swarm Mode commands:

  - `docker swarm` (enable Swarm mode; join a Swarm; adjust cluster parameters)

  - `docker node` (view nodes; promote/demote managers; manage nodes)

  - `docker service` (create and manage services)

???

- The Docker API exposes the same concepts

- The SwarmKit API is also exposed (on a separate socket)

---

## Swarm mode needs to be explicitly activated

- By default, all this new code is inactive

- Swarm mode can be enabled, "unlocking" SwarmKit functions
  <br/>(services, out-of-the-box overlay networks, etc.)

.lab[

- Try a Swarm-specific command:
  ```bash
  docker node ls
  ```

<!-- Ignore errors: ```wait not a swarm manager``` -->

]

--

You will get an error message:
```
Error response from daemon: This node is not a swarm manager. [...]
```
