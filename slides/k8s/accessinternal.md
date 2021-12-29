# Accessing internal services

- When we are logged in on a cluster node, we can access internal services

  (by virtue of the Kubernetes network model: all nodes can reach all pods and services)

- When we are accessing a remote cluster, things are different

  (generally, our local machine won't have access to the cluster's internal subnet)

- How can we temporarily access a service without exposing it to everyone?

--

- `kubectl proxy`: gives us access to the API, which includes a proxy for HTTP resources

- `kubectl port-forward`: allows forwarding of TCP ports to arbitrary pods, services, ...

---

## Suspension of disbelief

The labs and demos in this section assume that we have set up `kubectl` on our
local machine in order to access a remote cluster.

We will therefore show how to access services and pods of the remote cluster,
from our local machine.

You can also run these commands directly on the cluster (if you haven't
installed and set up `kubectl` locally).

Running commands locally will be less useful
(since you could access services and pods directly),
but keep in mind that these commands will work anywhere as long as you have
installed and set up `kubectl` to communicate with your cluster.

---

## `kubectl proxy` in theory

- Running `kubectl proxy` gives us access to the entire Kubernetes API

- The API includes routes to proxy HTTP traffic

- These routes look like the following:

  `/api/v1/namespaces/<namespace>/services/<service>/proxy`

- We just add the URI to the end of the request, for instance:

  `/api/v1/namespaces/<namespace>/services/<service>/proxy/index.html`

- We can access `services` and `pods` this way

---

## `kubectl proxy` in practice

- Let's access the `webui` service through `kubectl proxy`

.lab[

- Run an API proxy in the background:
  ```bash
  kubectl proxy &
  ```

- Access the `webui` service:
  ```bash
  curl localhost:8001/api/v1/namespaces/default/services/webui/proxy/index.html
  ```

- Terminate the proxy:
  ```bash
  kill %1
  ```

]

---

## `kubectl port-forward` in theory

- What if we want to access a TCP service?

- We can use `kubectl port-forward` instead

- It will create a TCP relay to forward connections to a specific port

  (of a pod, service, deployment...)

- The syntax is:

  `kubectl port-forward service/name_of_service local_port:remote_port`

- If only one port number is specified, it is used for both local and remote ports

---

## `kubectl port-forward` in practice

- Let's access our remote Redis server

.lab[

- Forward connections from local port 10000 to remote port 6379:
  ```bash
  kubectl port-forward svc/redis 10000:6379 &
  ```

- Connect to the Redis server:
  ```bash
  telnet localhost 10000
  ```

- Issue a few commands, e.g. `INFO server` then `QUIT`

<!--
```wait Connected to localhost```
```keys INFO server```
```key ^J```
```keys QUIT```
```key ^J```
-->

- Terminate the port forwarder:
  ```bash
  kill %1
  ```

]

???

:EN:- Securely accessing internal services
:FR:- Accès sécurisé aux services internes

:T: Accessing internal services from our local machine

:Q: What's the advantage of "kubectl port-forward" compared to a NodePort?
:A: It can forward arbitrary protocols
:A: It doesn't require Kubernetes API credentials
:A: It offers deterministic load balancing (instead of random)
:A: ✔️It doesn't expose the service to the public

:Q: What's the security concept behind "kubectl port-forward"?
:A: ✔️We authenticate with the Kubernetes API, and it forwards connections on our behalf
:A: It detects our source IP address, and only allows connections coming from it
:A: It uses end-to-end mTLS (mutual TLS) to authenticate our connections
:A: There is no security (as long as it's running, anyone can connect from anywhere)
