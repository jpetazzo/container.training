# Exercise — Ingress Secret Policy

- Most ingress controllers have access to all Secrets

  (so that they can access TLS keys and certs, which are stored in Secrets)

- Ingress controller vulnerability can lead to full cluster compromise

  (by allowing attacker to access all secrets, including API tokens)

- How can we prevent that?

---

## Preparation

- Deploy an ingress controller

- Deploy cert-manager

- Create a ClusterIssuer using Let's Encrypt

  (suggestion: also create a ClusterIssuer using LE's staging env)

- Create a trivial web app (e.g. NGINX, `jpetazzo/color`...)

- Create an Ingress for the app, with TLS enabled

- Tell cert-manager to obtain a certificate for that Ingress

  (suggestion: use the `cert-manager.io/cluster-issuer` annotation)

---

## Strategy

- Remove the ingress controller's permission to read all Secrets

- Grant selective access to Secrets

  (only give access to secrets that hold ingress TLS keys and certs)

- Automatically grant access by using Kyverno's "generate" mechanism

  (automatically create Role + RoleBinding when Certificate is created)

- Bonus: think about threat model for an insider attacker

  (and how to mitigate it)

---

## Goal

- When a Certificate (cert-manager CRD) is created, automatically create:

  - A Role granting read access to the Certificate's Secret

  - A RoleBinding granting that Role to our Ingress controller

- Check that the Ingress controller TLS still works

- ...But that the Ingress controller can't read other secrets
