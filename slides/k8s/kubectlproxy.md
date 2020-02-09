# Accessing the API with `kubectl proxy`

- The API requires us to authenticate.red[¹]

- There are many authentication methods available, including:

  - TLS client certificates
    <br/>
    (that's what we've used so far)

  - HTTP basic password authentication
    <br/>
    (from a static file; not recommended)

  - various token mechanisms
    <br/>
    (detailed in the [documentation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#authentication-strategies))

.red[¹]OK, we lied. If you don't authenticate, you are considered to
be user `system:anonymous`, which doesn't have any access rights by default.

---

## Accessing the API directly

- Let's see what happens if we try to access the API directly with `curl`

.exercise[

- Retrieve the ClusterIP allocated to the `kubernetes` service:
  ```bash
  kubectl get svc kubernetes
  ```

- Replace the IP below and try to connect with `curl`:
  ```bash
  curl -k https://`10.96.0.1`/
  ```

]

The API will tell us that user `system:anonymous` cannot access this path.

---

## Authenticating to the API

If we wanted to talk to the API, we would need to:

- extract our TLS key and certificate information from `~/.kube/config`

  (the information is in PEM format, encoded in base64)

- use that information to present our certificate when connecting

  (for instance, with `openssl s_client -key ... -cert ... -connect ...`)

- figure out exactly which credentials to use

  (once we start juggling multiple clusters)

- change that whole process if we're using another authentication method

🤔 There has to be a better way!

---

## Using `kubectl proxy` for authentication

- `kubectl proxy` runs a proxy in the foreground

- This proxy lets us access the Kubernetes API without authentication

  (`kubectl proxy` adds our credentials on the fly to the requests)

- This proxy lets us access the Kubernetes API over plain HTTP

- This is a great tool to learn and experiment with the Kubernetes API

- ... And for serious uses as well (suitable for one-shot scripts)

- For unattended use, it's better to create a [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

## Trying `kubectl proxy`

- Let's start `kubectl proxy` and then do a simple request with `curl`!

.exercise[

- Start `kubectl proxy` in the background:
  ```bash
  kubectl proxy &
  ```

- Access the API's default route:
  ```bash
  curl localhost:8001
  ```

<!--
```wait /version```
```key ^J```
-->

- Terminate the proxy:
  ```bash
  kill %1
  ```

]

The output is a list of available API routes.

---

## OpenAPI (fka Swagger)

- The Kubernetes API serves an OpenAPI Specification

  (OpenAPI was formerly known as Swagger)

- OpenAPI has many advantages

  (generate client library code, generate test code ...)

- For us, this means we can explore the API with [Swagger UI](https://swagger.io/tools/swagger-ui/)

  (for instance with the [Swagger UI add-on for Firefox](https://addons.mozilla.org/en-US/firefox/addon/swagger-ui-ff/))

---

## `kubectl proxy` is intended for local use

- By default, the proxy listens on port 8001

  (But this can be changed, or we can tell `kubectl proxy` to pick a port)

- By default, the proxy binds to `127.0.0.1`

  (Making it unreachable from other machines, for security reasons)

- By default, the proxy only accepts connections from:

  `^localhost$,^127\.0\.0\.1$,^\[::1\]$`

- This is great when running `kubectl proxy` locally

- Not-so-great when you want to connect to the proxy from a remote machine

---

class: extra-details

## Running `kubectl proxy` on a remote machine

- If we wanted to connect to the proxy from another machine, we would need to:

  - bind to `INADDR_ANY` instead of `127.0.0.1`

  - accept connections from any address

- This is achieved with:
  ```
  kubectl proxy --port=8888 --address=0.0.0.0 --accept-hosts=.*
  ```

.warning[Do not do this on a real cluster: it opens full unauthenticated access!]

---

class: extra-details

## Security considerations

- Running `kubectl proxy` openly is a huge security risk

- It is slightly better to run the proxy where you need it

  (and copy credentials, e.g. `~/.kube/config`, to that place)

- It is even better to use a limited account with reduced permissions

---

## Good to know ...

- `kubectl proxy` also gives access to all internal services

- Specifically, services are exposed as such:
  ```
  /api/v1/namespaces/<namespace>/services/<service>/proxy
  ```

- We can use `kubectl proxy` to access an internal service in a pinch

  (or, for non HTTP services, `kubectl port-forward`)

- This is not very useful when running `kubectl` directly on the cluster

  (since we could connect to the services directly anyway)

- But it is very powerful as soon as you run `kubectl` from a remote machine
