# GUI's: Web Admin of Swarms and Registry

What about web interfaces to control and manage Swarm?

- [Docker Enterprise](https://www.docker.com/products/docker-enterprise) is Docker Inc's paid offering, which has GUI's.

- [Portainer](https://portainer.io) is a popular open source web GUI for Swarm with node agents.

- [Portus](http://port.us.org) is a SUSE-backed open source web GUI for registry.

- Find lots of other Swarm tools in the [Awesome Docker list](https://awesome-docker.netlify.com).

---

## Lets deploy Portainer

- Yet another stack file

.lab[

- Make sure we are in the stacks directory:
  ```bash
  cd ~/container.training/stacks
  ```

- Deploy the Portainer stack:
  ```bash
  docker stack deploy -c portainer.yml portainer
  ```

]

---

## View and setup Portainer

- go to `<node ip>:9090`

- You should see the setup UI. Create a 8-digit password.

- Next, tell Portainer how to connect to docker.

- We'll use the agent method (one per node).

  - For connection, choose `Agent`

  - Name: `swarm1`

  - Agent URL: `tasks.agent:9001`

- Let's browse around the interface
