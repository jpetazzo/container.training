name: cicd

# CI/CD for Docker and orchestration

A quick note about continuous integration and deployment

- This lab won't have you building out CI/CD pipelines

- We're cheating a bit by building images on server hosts and not in CI tool

- Docker and orchestration works with all the CI and deployment tools

---

## CI/CD general process 

- Have your CI build your images, run tests *in them*, then push to registry

- If you security scan, do it then on your images after tests but before push

- Optionally, have CI do continuous deployment if build/test/push is successful

- CD tool would SSH into nodes, or use docker cli against remote engine

- If supported, it could use docker engine TCP API (swarm API is built-in)

- Docker KBase [Development Pipeline Best Practices](https://success.docker.com/article/dev-pipeline)

- Docker KBase [Continuous Integration with Docker Hub](https://success.docker.com/article/continuous-integration-with-docker-hub)

- Docker KBase [Building a Docker Secure Supply Chain](https://success.docker.com/article/secure-supply-chain)

---

class: pic

![CI-CD with Docker](images/ci-cd-with-docker.png)
