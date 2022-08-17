# Exercise — Network Policies

We want to to implement a generic network security mechanism.

Instead of creating one policy per service, we want to
create a fixed number of policies, and use a single label
to indicate the security level of our pods.

Then, when adding a new service to the stack, instead
of writing a new network policy for that service, we
only need to add the right label to the pods of that service.

---

## Specifications

We will use the label `security` to classify our pods.

- If `security=private`:

  *the pod shouldn't accept any traffic*

- If `security=public`:

  *the pod should accept all traffic*

- If `security=namespace`:

  *the pod should only accept connections coming from the same namespace*

If `security` isn't set, assume it's `private`.

---

## Test setup

- Deploy a copy of the DockerCoins app in a new namespace

- Modify the pod templates so that:

  - `webui` has `security=public`

  - `worker` has `security=private`

  - `hasher`, `redis`, `rng` have `security=namespace`

---

## Implement and test policies

- Write the network policies

  (feel free to draw inspiration from the ones we've seen so far)

- Check that:

  - you can connect to the `webui` from outside the cluster

  - the application works correctly (shows 3-4 hashes/second)

  - you cannot connect to the `hasher`, `redis`, `rng` services

  - you cannot connect or even ping the `worker` pods
