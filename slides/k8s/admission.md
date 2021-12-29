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

Some examples ...

- Stand-alone admission controllers

  *validating:* policy enforcement (e.g. quotas, naming conventions ...)

  *mutating:* inject or provide default values (e.g. pod presets)

- Admission controllers part of a greater system

  *validating:* advanced typing for operators

  *mutating:* inject sidecars for service meshes

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

## Developing a simple admission webhook

- We're going to register a custom webhook!

- First, we'll just dump the `AdmissionRequest` object

  (using a little Node app)

- Then, we'll implement a strict policy on a specific label

  (using a little Flask app)

- Development will happen in local containers, plumbed with ngrok

- The we will deploy to the cluster 🔥

---

## Running the webhook locally

- We prepared a Docker Compose file to start the whole stack

  (the Node "echo" app, the Flask app, and one ngrok tunnel for each of them)

.lab[

- Go to the webhook directory:
  ```bash
  cd ~/container.training/webhooks/admission
  ```

- Start the webhook in Docker containers:
  ```bash
  docker-compose up
  ```

]

*Note the URL in `ngrok-echo_1` looking like `url=https://xxxx.ngrok.io`.*

---

class: extra-details

## What's ngrok?

- Ngrok provides secure tunnels to access local services

- Example: run `ngrok http 1234`

- `ngrok` will display a publicly-available URL (e.g. https://xxxxyyyyzzzz.ngrok.io)

- Connections to https://xxxxyyyyzzzz.ngrok.io will terminate at `localhost:1234`

- Basic product is free; extra features (vanity domains, end-to-end TLS...) for $$$

- Perfect to develop our webhook!

- Probably not for production, though

  (webhook requests and responses now pass through the ngrok platform)

---

## Update the webhook configuration

- We have a webhook configuration in `k8s/webhook-configuration.yaml`

- We need to update the configuration with the correct `url`

.lab[

- Edit the webhook configuration manifest:
  ```bash
  vim k8s/webhook-configuration.yaml
  ```

- **Uncomment** the `url:` line

- **Update** the `.ngrok.io` URL with the URL shown by Compose

- Save and quit

]

---

## Register the webhook configuration

- Just after we register the webhook, it will be called for each matching request

  (CREATE and UPDATE on Pods in all namespaces)

- The `failurePolicy` is `Ignore`

  (so if the webhook server is down, we can still create pods)

.lab[

- Register the webhook:
  ```bash
  kubectl apply -f k8s/webhook-configuration.yaml
  ```

]

It is strongly recommended to tail the logs of the API server while doing that.

---

## Create a pod

- Let's create a pod and try to set a `color` label

.lab[

- Create a pod named `chroma`:
  ```bash
  kubectl run --restart=Never chroma --image=nginx
  ```

- Add a label `color` set to `pink`:
  ```bash
  kubectl label pod chroma color=pink
  ```

]

We should see the `AdmissionReview` objects in the Compose logs.

Note: the webhook doesn't do anything (other than printing the request payload).

---

## Use the "real" admission webhook

- We have a small Flask app implementing a particular policy on pod labels:

  - if a pod sets a label `color`, it must be `blue`, `green`, `red`

  - once that `color` label is set, it cannot be removed or changed

- That Flask app was started when we did `docker-compose up` earlier

- It is exposed through its own ngrok tunnel

- We are going to use that webhook instead of the other one

  (by changing only the `url` field in the ValidatingWebhookConfiguration)

---

## Update the webhook configuration

.lab[

- First, check the ngrok URL of the tunnel for the Flask app:
  ```bash
  docker-compose logs ngrok-flask
  ```

- Then, edit the webhook configuration:
  ```bash
  kubectl edit validatingwebhookconfiguration admission.container.training
  ```
- Find the `url:` field with the `.ngrok.io` URL and update it

- Save and quit; the new configuration is applied immediately

]

---

## Verify the behavior of the webhook

- Try to create a few pods and/or change labels on existing pods

- What happens if we try to make changes to the earlier pod?

  (the one that has `label=pink`)

---

## Deploying the webhook on the cluster

- Let's see what's needed to self-host the webhook server!

- The webhook needs to be reachable through a Service on our cluster

- The Service needs to accept TLS connections on port 443

- We need a proper TLS certificate:

  - with the right `CN` and `subjectAltName` (`<servicename>.<namespace>.svc`)

  - signed by a trusted CA

- We can either use a "real" CA, or use the `caBundle` option to specify the CA cert

  (the latter makes it easy to use self-signed certs)

---

## In practice

- We're going to generate a key pair and a self-signed certificate

- We will store them in a Secret

- We will run the webhook in a Deployment, exposed with a Service

- We will update the webhook configuration to use that Service

- The Service will be named `admission`, in Namespace `webhooks`

  (keep in mind that the ValidatingWebhookConfiguration itself is at cluster scope)

---

## Let's get to work!

.lab[

- Make sure we're in the right directory:
  ```bash
  cd ~/container.training/webhooks/admission
  ```

- Create the namespace:
  ```bash
  kubectl create namespace webhooks
  ```

- Switch to the namespace:
  ```bash
  kubectl config set-context --current --namespace=webhooks
  ```

]

---

## Deploying the webhook

- *Normally,* we would author an image for this

- Since our webhook is just *one* Python source file ...

  ... we'll store it in a ConfigMap, and install dependencies on the fly

.lab[

- Load the webhook source in a ConfigMap:
  ```bash
  kubectl create configmap admission --from-file=flask/webhook.py
  ```

- Create the Deployment and Service:
  ```bash
  kubectl apply -f k8s/webhook-server.yaml
  ```

]

---

## Generating the key pair and certificate

- Let's call OpenSSL to the rescue!

  (of course, there are plenty others options; e.g. `cfssl`)

.lab[

- Generate a self-signed certificate:
  ```bash
    NAMESPACE=webhooks
    SERVICE=admission
    CN=$SERVICE.$NAMESPACE.svc
    openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem \
        -days 30 -subj /CN=$CN -addext subjectAltName=DNS:$CN
  ```

- Load up the key and cert in a Secret:
  ```bash
  kubectl create secret tls admission --cert=cert.pem --key=key.pem
  ```

]

---

## Update the webhook configuration

- Let's reconfigure the webhook to use our Service instead of ngrok

.lab[

- Edit the webhook configuration manifest:
  ```bash
  vim k8s/webhook-configuration.yaml
  ```

- Comment out the `url:` line

- Uncomment the `service:` section

- Save, quit

- Update the webhook configuration:
  ```bash
  kubectl apply -f k8s/webhook-configuration.yaml
  ```

]

---

## Add our self-signed cert to the `caBundle`

- The API server won't accept our self-signed certificate

- We need to add it to the `caBundle` field in the webhook configuration

- The `caBundle` will be our `cert.pem` file, encoded in base64

---

Shell to the rescue!

.lab[

- Load up our cert and encode it in base64:
  ```bash
  CA=$(base64 -w0 < cert.pem)
  ```

- Define a patch operation to update the `caBundle`:
  ```bash
    PATCH='[{
        "op": "replace",
        "path": "/webhooks/0/clientConfig/caBundle",
        "value":"'$CA'"
    }]'
  ```

- Patch the webhook configuration:
  ```bash
    kubectl patch validatingwebhookconfiguration \
                  admission.webhook.container.training \
                  --type='json' -p="$PATCH"
  ```

]

---

## Try it out!

- Keep an eye on the API server logs

- Tail the logs of the pod running the webhook server

- Create a few pods; we should see requests in the webhook server logs

- Check that the label `color` is enforced correctly

  (it should only allow values of `red`, `green`, `blue`)

???

:EN:- Dynamic admission control with webhooks
:FR:- Contrôle d'admission dynamique (webhooks)
