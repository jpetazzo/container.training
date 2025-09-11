# Cloud Native Security

*Non-exhaustive list of best practices for Cloud Native Security.*

---

## "Less is more"

- Less code (build vs buy; Pareto 80/20)

- Less permissions (fine-grained vs blanket)

- Less dependencies (also a trade-off)

*Note: this is not at all specific to Cloud Native.*

*But security must be addressed at all layers of the stack!*

---

## Managed platforms

- Operating Kubernetes is complex

- Use a managed platform

  (cloud provider or service provider)

- Restrict control plane access

- TLS cert management (check "PKI the wrong way")

- Enable Pod Security Settings

- Restrict access to cloud instance metadata

---

## K8S upgrades

- ALWAYS ALWAYS ALWAYS upgrade

  (do you prefer your maintenance to be planned or unplanned?)

- Upgrades can be smooth if:

  - we're using a good, managed platform

  - we stay away from beta APIs

---

## Isolate compute

- Resource requests and limits for ALL workloads

- Taints, tolerations, affinities where necessary

- Secure container runtime if necessary

---

## Isolate network

- Network policies

- Advanced policies (check Cilium)

---

## Secret management

- Secrets vs ConfigMaps

- Store secrets in...:

  - KMS
  - External Secrets
  - Sealed Secrets
  - Vault
  - Kamus
  - SOPS
  - ...

- Encrypt secrets at rest if necessary

---

## AuthN & AuthZ

- Authenticate users centrally

  (e.g. OIDC, certificates)

- Have a clear path for access revocation

- Fine-grained RBAC

---

## Software supply chain

*I'm not an expert in that field but this should be on your radar!*
