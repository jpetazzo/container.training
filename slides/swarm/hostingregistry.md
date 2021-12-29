# Hosting our own registry

- We need to run a `registry` container

- It will store images and layers to the local filesystem
  <br/>(but you can add a config file to use S3, Swift, etc.)

- Docker *requires* TLS when communicating with the registry

  - unless for registries on `127.0.0.0/8` (i.e. `localhost`)

  - or with the Engine flag `--insecure-registry`

<!-- -->

- Our strategy: publish the registry container on port 5000,
  <br/>so that it's available through `127.0.0.1:5000` on each node

---

## Deploying the registry

- We will create a single-instance service, publishing its port
  on the whole cluster

.lab[

- Create the registry service:
  ```bash
  docker service create --name registry --publish 5000:5000 registry
  ```

- Now try the following command; it should return `{"repositories":[]}`:
  ```bash
  curl 127.0.0.1:5000/v2/_catalog
  ```

]
