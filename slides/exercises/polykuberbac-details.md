# Exercise — Enable RBAC

- We want to enable RBAC on the "polykube" cluster

  (it doesn't matter whether we have 1 or multiple nodes)

- Ideally, we want to have, for instance:

  - one key, certificate, and kubeconfig for a cluster admin

  - one key, certificate, and kubeconfig for a user
    <br/>
    (with permissions in a single namespace)

- Bonus points: enable the NodeAuthorizer too!

- Check the following slides for hints

---

## Step 1

- Enable RBAC itself!

--

- This is done with an API server command-line flag

--

- Check [the documentation][kube-apiserver-doc] to see the flag

--

- For now, only enable `--authorization-mode=RBAC`

[kube-apiserver-doc]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/

---

## Step 2

- Our certificate doesn't work anymore, we need to generate a new one

--

- We need a certificate that will have *some* (ideally *all*) permissions

--

- Two options:

  - use the equivalent of "root" (identity that completely skips permission checks)

  - a "non-root" identity but which is granted permissions with RBAC

--

- The "non-root" option looks nice, but to grant permissions, we need permissions

- So let's start with the equivalent of "root"!

--

- The Kubernetes equivalent of `root` is the group `system:masters`

---

## Step 2, continued

- We need to generate a certificate for a user belonging to group `system:masters`

--

- In Kubernetes certificates, groups are encoded with the "organization" field

--

- That corresponds to `O=system:masters`

--

- In other words we need to generate a new certificate, but with a subject of:

  `/CN=admin/O=system:masters/` (the `CN` doesn't matter)

- That certificate should be able to interact with the API server, like before

---

## Step 3

- Now, all our controllers have permissions issues

- We need to either:

  - use that `system:masters` cert everywhere

  - generate different certs for every controller, with the proper identities

- Suggestion: use `system-masters` everywhere to begin with

  (and make sure the cluster is back on its feet)

---

## Step 4

At this point, there are two possible forks in the road:

1. Generate certs for the control plane controllers

   (`kube-controller-manager`, `kube-scheduler`)

2. Generate cert(s) for the node(s) and enable `NodeAuthorizer`

Good luck!
