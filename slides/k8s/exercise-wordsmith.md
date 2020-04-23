# Exercise — deploying on Kubernetes

Let's deploy the wordsmith app on Kubernetes!

As a reminder, we have the following components:

| Name  | Image                           | Port |
|-------|---------------------------------|------|
| db    | jpetazzo/wordsmith-db:latest    | 5432 |
| web   | jpetazzo/wordsmith-web:latest   | 80   |
| words | jpetazzo/wordsmith-words:latest | 8080 |

We need `web` to be available from outside the cluster.

See next slide if you need hints!

---

## Hints

*Scroll one slide at a time to see hints.*

--

- For each component, we need to create a deployment and a service

--

- Deployments can be created with `kubectl create deployment`

--

- Services can be created with `kubectl expose`

--

- Public services (like `web`) need to use a special type

  (e.g. `NodePort`)
