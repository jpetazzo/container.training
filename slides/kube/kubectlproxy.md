# Accessing internal services with `kubectl proxy`

- `kubectl proxy` runs a proxy in the foreground

- This proxy lets us access the Kubernetes API without authentication

  (`kubectl proxy` adds our credentials on the fly to the requests)

- This proxy lets us access the Kubernetes API over plain HTTP

- This is a great tool to learn and experiment with the Kubernetes API

- The Kubernetes API also gives us a proxy to HTTP and HTTPS services

- Therefore, we can use `kubectl proxy` to access internal services

  (Without using a `NodePort` or similar service)

---

## Secure by default

- By default, the proxy listens on port 8001

  (But this can be changed, or we can tell `kubectl proxy` to pick a port)

- By default, the proxy binds to `127.0.0.1`

  (Making it unreachable from other machines, for security reasons)

- By default, the proxy only accepts connections from:

  `^localhost$,^127\.0\.0\.1$,^\[::1\]$`

- This is great when running `kubectl proxy` locally

- Not-so-great when running it on a remote machine

---

## Running `kubectl proxy` on a remote machine

- We are going to bind to `INADDR_ANY` instead of `127.0.0.1`

- We are going to accept connections from any address

.exercise[

- Run an open proxy to the Kubernetes API:
  ```bash
  kubectl proxy --port=8888 --address=0.0.0.0 --accept-hosts=.*
  ```

]

.warning[Anyone can now do whatever they want with our Kubernetes cluster!
<br/>
(Don't do this on a real cluster!)]

---

## Viewing available API routes

- The default route (i.e. `/`) shows a list of available API endpoints

.exercise[

- Point your browser to the IP address of the node running `kubectl proxy`, port 8888

]

The result should look like this:
```json
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/",
    "/apis/admissionregistration.k8s.io",
    …
```

---

## Connecting to a service through the proxy

- The API can proxy HTTP and HTTPS requests by accessing a special route:
  ```
  /api/v1/namespaces/`name_of_namespace`/services/`name_of_service`/proxy
  ```

- Since we now have access to the API, we can use this special route

.exercise[

- Access the `hasher` service through the special proxy route:
  ```open
  http://`X.X.X.X`:8888/api/v1/namespaces/default/services/hasher/proxy
  ```

]

You should see the banner of the hasher service: `HASHER running on ...`

---

## Stopping the proxy

- Remember: as it is running right now, `kubectl proxy` gives open access to our cluster

.exercise[

- Stop the `kubectl proxy` process with Ctrl-C

]

