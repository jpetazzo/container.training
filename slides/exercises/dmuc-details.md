# Exercise — Build a Cluster

- Step 1: deploy a cluster

  - follow the steps in the "Dessine-moi un cluster" section

- Step 2: add CNI networking

  - une kube-router

  - interconnect with the route-reflector

  - check that you receive the routes of other clusters

- Step 3: generate and validate ServiceAccount tokens

  - see next slide for help!

---

## ServiceAccount tokens

- We need to generate a TLS key pair and certificate

- A self-signed key will work

- We don't need anything particular in the certificate

  (no particular CN, key use flags, etc.)

- The key needs to be passed to both API server and controller manager

- Check that ServiceAccount tokens are generated correctly
