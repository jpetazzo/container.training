# Exercise — sealed secrets

This is a "combo exercise" to practice the following concepts:

- Secrets (mounting them in containers)

- RBAC (granting specific permissions to specific users)

- Operators (specifically, sealed secrets)

- Migrations (copying/transferring resources from a cluster to another)

For this exercise, you will need two clusters.

(It can be two local clusters.)

We will call them "source cluster" and "target cluster".

---

## Step 1 (easy)

- Install the sealed secrets operator on both clusters

- On source cluster, create a Namespace called `dev`

- Create two sealed secrets, `verysecure` and `veryverysecure`

  (the content doesn't matter; put a random string of your choice)

- Create a Deployment called `app` using both secrets

  (use a mount or environment variables; whatever you prefer!)

- Verify that the secrets are available to the Deployment

---

## Step 2 (medium)

- Create another Namespace called `prod`

  (on the source cluster)

- Create the same Deployment `app` using both secrets

- Verify that the secrets are available to the Deployment

---

## Step 3 (hard)

- On the target cluster, create a Namespace called `prod`

- Create the `app` Deployment and both sealed secrets

  (do not copy the Secrets; only the sealed secrets)

- Check the next slide if you need a hint!

--

- You will have to copy the Sealed Secret private key

---

## Step 4 (medium)

On the target cluster, create the Namespace `dev`.

Let's say that user `alice` has access to the target cluster.

(You can use `kubectl --as=alice` to impersonate her.)

We want Alice to be able to:

- deploy the whole application

- access the `verysecure` secret

- but *not* the `veryverysecure` secret

---

## Step 5 (hard)

- Make sure that Alice can view the logs of the Deployment

- Can you think of a way for Alice to access the `veryverysecure` Secret?

  (check next slide for a hint)

--

- `kubectl exec`, maybe?

--

- Can you think of a way to prevent that?
