## Optimizing request flow

- With most ingress controllers, requests follow this path:

  HTTP client → load balancer → NodePort → ingress controller Pod → app Pod

- Sometimes, some of these components can be on the same machine

  (e.g. ingress controller Pod and app Pod)

- But they can also be on different machines

  (each arrow = a potential hop)

- This could add some unwanted latency!

(See following diagrams)

---

class: pic

![](images/kubernetes-services/61-ING.png)

---

class: pic

![](images/kubernetes-services/62-ING-path.png)

---

## External traffic policy

- The Service manifest has a field `spec.externalTrafficPolicy`

- Possible values are:

  - `Cluster` (default) - load balance connections to all pods

  - `Local` - only send connections to local pods (on the same node)

- When the policy is set to `Local`, we avoid one hop:

  HTTP client → load balancer → NodePort .red[**→**] ingress controller Pod → app Pod

(See diagram on next slide)

---

class: pic

![](images/kubernetes-services/63-ING-policy.png)

---

## What if there is no Pod?

- If a connection for a Service arrives on a Node through a NodePort...

- ...And that Node doesn't host a Pod matching the selector of that Service...

  (i.e. there is no local Pod)

- ...Then the connection is refused

- This can be detected from outside (by the external load balancer)

- The external load balancer won't send connections to these nodes

(See diagram on next slide)

---

class: pic

![](images/kubernetes-services/64-ING-nolocal.png)

---

class: extra-details

## Internal traffic policy

- Since Kubernetes 1.21, there is also `spec.internalTrafficPolicy`

- It works similarly but for internal traffic

- It's an *alpha* feature

  (not available by default; needs special steps to be enabled on the control plane)

- See the [documentation] for more details

[documentation]: https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/

---

## Other ways to save hops

- Run the ingress controller as a DaemonSet, using port 80 on the nodes:

  HTTP client → load balancer → ingress controller on Node port 80 → app Pod

- Then simplify further by setting a set of DNS records pointing to the nodes:

  HTTP client → ingress controller on Node port 80 → app Pod 

- Or run a combined load balancer / ingress controller at the edge of the cluster:

  HTTP client → edge ingress controller → app Pod

---

## Source IP address

- Obtaining the IP address of the HTTP client (from the app Pod) can be tricky!

- We should consider (at least) two steps:

  - obtaining the IP address of the HTTP client (from the ingress controller)

  - passing that IP address from the ingress controller to the HTTP client

- The second step is usually done by injecting an HTTP header

  (typically `x-forwarded-for`)

- Most ingress controllers do that out of the box

- But how does the ingress controller obtain the IP address of the HTTP client? 🤔

---

## Scenario 1, direct connection

- If the HTTP client connects directly to the ingress controller: easy!

  - e.g. when running a combined load balancer / ingress controller

  - or when running the ingress controller as a Daemon Set directly on port 80

---

## Scenario 2, external load balancer

- Most external load balancers running in TCP mode don't expose client addresses

  (HTTP client connects to load balancer; load balancer connects to ingress controller)

- The ingress controller will "see" the IP address of the load balancer

  (instead of the IP address of the client)

- Many external load balancers support the [Proxy Protocol]

- This enables the ingress controller to "see" the IP address of the HTTP client

- It needs to be enabled on both ends (ingress controller and load balancer)

[ProxyProtocol]: https://www.haproxy.com/blog/haproxy/proxy-protocol/

---

## Scenario 3, leveraging `externalTrafficPolicy`

- In some cases, the external load balancer will preserve the HTTP client address

- It is then possible to set `externalTrafficPolicy` to `Local`

- The ingress controller will then "see" the HTTP client address

- If `externalTrafficPolicy` is set to `Cluster`:

  - sometimes the client address will be visible

  - when bouncing the connection to another node, the address might be changed

- This is a big "it depends!"

- Bottom line: rely on the two other techniques instead?
