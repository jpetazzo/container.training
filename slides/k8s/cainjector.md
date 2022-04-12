## CA injector - overview

- The Kubernetes API server can invoke various webhooks:

  - conversion webhooks (registered in CustomResourceDefinitions)

  - mutation webhooks (registered in MutatingWebhookConfigurations)

  - validation webhooks (registered in ValidatingWebhookConfiguration)

- These webhooks must be served over TLS

- These webhooks must use valid TLS certificates

---

## Webhook certificates

- Option 1: certificate issued by a global CA

  - doesn't work with internal services
    <br/>
    (their CN must be `<servicename>.<namespace>.svc`)

- Option 2: certificate issued by private CA + CA certificate in system store

  - requires access to API server certificates tore

  - generally not doable on managed Kubernetes clusters

- Option 3: certificate issued by private CA + CA certificate in `caBundle`

  - pass the CA certificate in `caBundle` field
    <br/>
    (in CRD or webhook manifests)

  - can be managed automatically by cert-manager

---

## CA injector - details

- Add annotation to *injectable* resource
  (CustomResouceDefinition, MutatingWebhookConfiguration, ValidatingWebhookConfiguration)

- Annotation refers to the thing holding the certificate:

  - `cert-manager.io/inject-ca-from: <namespace>/<certificate>`

  - `cert-manager.io/inject-ca-from-secret: <namespace>/<secret>`

  - `cert-manager.io/inject-apiserver-ca: true` (use API server CA)

- When injecting from a Secret, the Secret must have a special annotation:

  `cert-manager.io/allow-direct-injection: "true"`

- See [cert-manager documentation][docs] for details

[docs]: https://cert-manager.io/docs/concepts/ca-injector/
