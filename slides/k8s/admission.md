# Dynamic Admission Control

- This is one of the many ways to extend the Kubernetes API

- High level summary: dynamic admission control relies on webhooks that are ...

  - dynamic (can be added/removed on the fly)

  - running inside our outside the cluster

  - *validating* (yay/nay) or *mutating* (can change objects that are created/updated)

  - selective (can be configured to apply only to some kinds, some selectors...)

  - mandatory or optional (should it block operations when webhook is down?)

- Used for themselves (e.g. policy enforcement) or as part of operators

---

## Use cases

- Defaulting

  *injecting image pull secrets, sidecars, environment variables...*

- Policy enforcement and best practices

  *prevent: `latest` images, deprecated APIs...*

  *require: PDBs, resource requests/limits, labels/annotations, local registry...*

- Problem mitigation

  *block nodes with vulnerable kernels, inject log4j mitigations, rewrite images...*

- Extended validation for operators

---

## You said *dynamic?*

- Some admission controllers are built in the API server

- They are enabled/disabled through Kubernetes API server configuration

  (e.g. `--enable-admission-plugins`/`--disable-admission-plugins` flags)

- Here, we're talking about *dynamic* admission controllers

- They can be added/remove while the API server is running

  (without touching the configuration files or even having access to them)

- This is done through two kinds of cluster-scope resources:

  ValidatingWebhookConfiguration and MutatingWebhookConfiguration

---

## You said *webhooks?*

- A ValidatingWebhookConfiguration or MutatingWebhookConfiguration contains:

  - a resource filter
    <br/>
    (e.g. "all pods", "deployments in namespace xyz", "everything"...)

  - an operations filter
    <br/>
    (e.g. CREATE, UPDATE, DELETE)

  - the address of the webhook server

- Each time an operation matches the filters, it is sent to the webhook server

---

## What gets sent exactly?

- The API server will `POST` a JSON object to the webhook

- That object will be a Kubernetes API message with `kind` `AdmissionReview`

- It will contain a `request` field, with, notably:

  - `request.uid` (to be used when replying)

  - `request.object` (the object created/deleted/changed)

  - `request.oldObject` (when an object is modified)

  - `request.userInfo` (who was making the request to the API in the first place)

(See [the documentation](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#request) for a detailed example showing more fields.)

---

## How should the webhook respond?

- By replying with another `AdmissionReview` in JSON

- It should have a `response` field, with, notably:

  - `response.uid` (matching the `request.uid`)

  - `response.allowed` (`true`/`false`)

  - `response.status.message` (optional string; useful when denying requests)

  - `response.patchType` (when a mutating webhook changes the object; e.g. `json`)

  - `response.patch` (the patch, encoded in base64)

---

## What if the webhook *does not* respond?

- If "something bad" happens, the API server follows the `failurePolicy` option

  - this is a per-webhook option (specified in the webhook configuration)

  - it can be `Fail` (the default) or `Ignore` ("allow all, unmodified")

- What's "something bad"?

  - webhook responds with something invalid

  - webhook takes more than 10 seconds to respond
    <br/>
    (this can be changed with `timeoutSeconds` field in the webhook config)

  - webhook is down or has invalid certificates
    <br/>
    (TLS! It's not just a good idea; for admission control, it's the law!)

---

## What did you say about TLS?

- The webhook configuration can indicate:

  - either `url` of the webhook server (has to begin with `https://`)

  - or `service.name` and `service.namespace` of a Service on the cluster

- In the latter case, the Service has to accept TLS connections on port 443

- It has to use a certificate with CN `<name>.<namespace>.svc`

  (**and** a `subjectAltName` extension with `DNS:<name>.<namespace>.svc`)

- The certificate needs to be valid (signed by a CA trusted by the API server)

  ... alternatively, we can pass a `caBundle` in the webhook configuration

---

## Webhook server inside or outside

- "Outside" webhook server is defined with `url` option

  - convenient for external webooks (e.g. tamper-resistent audit trail)

  - also great for initial development (e.g. with ngrok)

  - requires outbound connectivity (duh) and can become a SPOF

- "Inside" webhook server is defined with `service` option

  - convenient when the webhook needs to be deployed and managed on the cluster

  - also great for air gapped clusters

  - development can be harder (but tools like [Tilt](https://tilt.dev) can help)

---

## Real world examples

- [kube-image-keeper][kuik] rewrites image references to use cached images

  (e.g. `nginx` → `localhost:7439/nginx`)

- [Kyverno] implements very extensive policies

  (validation, generation... it deserves a whole chapter on its own!)

[kuik]: https://github.com/enix/kube-image-keeper
[kyverno]: https://kyverno.io/

---

## Alternatives

- Kubernetes Validating Admission Policies

- Relatively recent (alpha: 1.26, beta: 1.28, GA: 1.30)

- Declare validation rules with Common Expression Language ([CEL][cel-spec])

- Validation is done entirely within the API server

  (no external webhook = no latency, no deployment complexity...)

- Not as powerful as full-fledged webhook engines like Kyverno

  (see e.g. [this page of the Kyverno doc][kyverno-vap] for a comparison)

[kyverno-vap]: https://kyverno.io/docs/policy-types/validating-policy/
[cel-spec]: https://github.com/google/cel-spec

???

:EN:- Dynamic admission control with webhooks
:FR:- Contrôle d'admission dynamique (webhooks)
