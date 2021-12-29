class: secrets

## Secret management

- Docker has a "secret safe" (secure key→value store)

- You can create as many secrets as you like

- You can associate secrets to services

- Secrets are exposed as plain text files, but kept in memory only (using `tmpfs`)

- Secrets are immutable (at least in Engine 1.13)

- Secrets have a max size of 500 KB

---

class: secrets

## Creating secrets

- Must specify a name for the secret; and the secret itself

.lab[

- Assign [one of the four most commonly used passwords](https://www.youtube.com/watch?v=0Jx8Eay5fWQ) to a secret called `hackme`:
  ```bash
  echo love | docker secret create hackme -
  ```

]

If the secret is in a file, you can simply pass the path to the file.

(The special path `-` indicates to read from the standard input.)

---

class: secrets

## Creating better secrets

- Picking lousy passwords always leads to security breaches

.lab[

- Let's craft a better password, and assign it to another secret:
  ```bash
  base64 /dev/urandom | head -c16 | docker secret create arewesecureyet -
  ```

]

Note: in the latter case, we don't even know the secret at this point. But Swarm does.

---

class: secrets

## Using secrets

- Secrets must be handed explicitly to services

.lab[

- Create a dummy service with both secrets:
  ```bash
    docker service create \
           --secret hackme --secret arewesecureyet \
           --name dummyservice \
           --constraint node.hostname==$HOSTNAME \
           alpine sleep 1000000000
  ```

]

We constrain the container to be on the local node for convenience.
<br/>
(We are going to use `docker exec` in just a moment!)

---

class: secrets

## Accessing secrets

- Secrets are materialized on `/run/secrets` (which is an in-memory filesystem)

.lab[

- Find the ID of the container for the dummy service:
  ```bash
  CID=$(docker ps -q --filter label=com.docker.swarm.service.name=dummyservice)
  ```

- Enter the container:
  ```bash
  docker exec -ti $CID sh
  ```

- Check the files in `/run/secrets`

<!-- ```bash grep . /run/secrets/*``` -->
<!-- ```bash exit``` -->

]

---

class: secrets

## Rotating secrets

- You can't change a secret

  (Sounds annoying at first; but allows clean rollbacks if a secret update goes wrong)

- You can add a secret to a service with `docker service update --secret-add`

  (This will redeploy the service; it won't add the secret on the fly)

- You can remove a secret with `docker service update --secret-rm`

- Secrets can be mapped to different names by expressing them with a micro-format:
  ```bash
  docker service create --secret source=secretname,target=filename
  ```

---

class: secrets

## Changing our insecure password

- We want to replace our `hackme` secret with a better one

.lab[

- Remove the insecure `hackme` secret:
  ```bash
  docker service update dummyservice --secret-rm hackme
  ```

- Add our better secret instead:
  ```bash
  docker service update dummyservice \
         --secret-add source=arewesecureyet,target=hackme
  ```

]

Wait for the service to be fully updated with e.g. `watch docker service ps dummyservice`.
<br/>(With Docker Engine 17.10 and later, the CLI will wait for you!)

---

class: secrets

## Checking that our password is now stronger

- We will use the power of `docker exec`!

.lab[

- Get the ID of the new container:
  ```bash
  CID=$(docker ps -q --filter label=com.docker.swarm.service.name=dummyservice)
  ```

- Check the contents of the secret files:
  ```bash
  docker exec $CID grep -r . /run/secrets
  ```

]

---

class: secrets

## Secrets in practice

- Can be (ab)used to hold whole configuration files if needed

- If you intend to rotate secret `foo`, call it `foo.N` instead, and map it to `foo`

  (N can be a serial, a timestamp...)

  ```bash
  docker service create --secret source=foo.N,target=foo ...
  ```

- You can update (remove+add) a secret in a single command:

  ```bash
  docker service update ... --secret-rm foo.M --secret-add source=foo.N,target=foo
  ```

- For more details and examples, [check the documentation](https://docs.docker.com/engine/swarm/secrets/)
