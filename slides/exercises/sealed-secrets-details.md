# Exercise — Sealed Secrets

This is a "combo exercise" to practice the following concepts:

- Secrets (exposing them in containers)

- RBAC (granting specific permissions to specific users)

- Operators (specifically, sealed secrets)

- Migrations (copying/transferring resources from a cluster to another)

For this exercise, you will need two clusters.

(It can be two local clusters.)

We will call them "dev cluster" and "prod cluster".

---

## Overview

- For simplicity, our application will be NGINX (or `jpetazzo/color`)

- Our application needs two secrets:

  - a *logging API token* (not too sensitive; same in dev and prod)

  - a *database password* (sensitive; different in dev and prod)

- Secrets can be exposed as env vars, or mounted in volumes

  (it doesn't matter for this exercise)

- We want to prepare and deploy the application in the dev cluster

- ...Then deploy it to the prod cluster

---

## Step 1 (easy)

- On the dev cluster, create a Namespace called `dev`

- Create the two secrets, `logging-api-token` and `database-password`

  (the content doesn't matter; put a random string of your choice)

- Create a Deployment called `app` using both secrets

  (use a mount or environment variables; whatever you prefer!)

- Verify that the secrets are available to the Deployment

  (e.g. with `kubectl exec`)

- Generate YAML manifests for the application (Deployment+Secrets)

---

## Step 2 (medium)

- Deploy the sealed secrets operator on the dev cluster

- In the YAML, replace the Secrets with SealedSecrets

- Delete the `dev` Namespace, recreate it, redeploy the app

  (to make sure everything works fine)

- Create a `staging` Namespace and try to deploy the app

- If something doesn't work, fix it

--

- Hint: set the *scope* of the sealed secrets

---

## Step 3 (hard)

- On the prod cluster, create a Namespace called `prod`

- Try to deploy the application using the YAML manifests

- It won't work (the cluster needs the sealing key)

- Fix it!

  (check the next slides if you need hints)

--

- You will have to copy the Sealed Secret private key

--

- And restart the operator so that it picks up the key

---

## Step 4 (medium)

Let's say that we have a user called `alice` on the prod cluster.

(You can use `kubectl --as=alice` to impersonate her.)

We want Alice to be able to:

- deploy the whole application in the `prod` namespace

- access the *logging API token* secret

- but *not* the *database password* secret

- view the logs of the app
