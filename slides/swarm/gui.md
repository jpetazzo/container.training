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

---

## Portainer API - Advanced privileges

- setup a non administrative user

- deploy an app template via portainer with only administrator rights

- deploy an app template via portainer with rights for the created user

- do `http POST :9000/api/auth Username="$USER" Password="$PASSWORD"`

- now try to query the deployed stacks `http GET :9000/api/stacks "Authorization: Bearer $TOKEN"`
  you will only see the stack with the user rights

- you could prevent access for stacks like monitoring, log-forwarding and the portainer agent

---

## Single GUI/API for multiple swarms

- setup 2 swarms instead of one swarm with 3 nodes

- install the portainer agent on both swarms

```
docker service create \
    --name portainer_agent \
    --network portainer_agent_network \
    --publish mode=host,target=9001,published=9001 \
    -e AGENT_CLUSTER_ADDR=tasks.portainer_agent \
    --mode global \
    --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
    --mount type=bind,src=//var/lib/docker/volumes,dst=/var/lib/docker/volumes \
    portainer/agent
```

- now go to portainer and add both agents as endpoint

- now you can deploy stacks via one api on multiple docker swarms

- deploy a stack on swarm2

```
http POST ':9000/api/stacks?method=repository&type=1&endpointId=2' \
  "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwidXNlcm5hbWUiOiJ1c2VyMSIsInJvbGUiOjIsImV4cCI6MTU0MTQ5MDg4OH0.9hVYxfSfdNAnQDRfEsH9-EcQkI9aL3beEmxJz8_6uOI" \
  Name="Voting" \
  RepositoryURL="https://github.com/BretFisher/example-voting-app" \
  ComposeFilePathInRepository="docker-stack.yml" \
  SwarmID="$SWARMID"
```