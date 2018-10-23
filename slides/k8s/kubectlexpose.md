# Exposing containers

- `kubectl expose` creates a *service* for existing pods

- A *service* is a stable address for a pod (or a bunch of pods)

- If we want to connect to our pod(s), we need to create a *service*

- Once a service is created, CoreDNS will allow us to resolve it by name

  (i.e. after creating service `hello`, the name `hello` will resolve to something)

- There are different types of services, detailed on the following slides:

  `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`

---

## Basic service types

- `ClusterIP` (default type)

  - a virtual IP address is allocated for the service (in an internal, private range)
  - this IP address is reachable only from within the cluster (nodes and pods)
  - our code can connect to the service using the original port number

- `NodePort`

  - a port is allocated for the service (by default, in the 30000-32768 range)
  - that port is made available *on all our nodes* and anybody can connect to it
  - our code must be changed to connect to that new port number

These service types are always available.

Under the hood: `kube-proxy` is using a userland proxy and a bunch of `iptables` rules.

---

## More service types

- `LoadBalancer`

  - an external load balancer is allocated for the service
  - the load balancer is configured accordingly
    <br/>(e.g.: a `NodePort` service is created, and the load balancer sends traffic to that port)
  - available only when the underlying infrastructure provides some "load balancer as a service"
    <br/>(e.g. AWS, Azure, GCE, OpenStack...)

- `ExternalName`

  - the DNS entry managed by CoreDNS will just be a `CNAME` to a provided record
  - no port, no IP address, no nothing else is allocated

---

## Running containers with open ports

- Since `ping` doesn't have anything to connect to, we'll have to run something else

.exercise[

- Start a bunch of HTTP servers:
  ```bash
  kubectl run httpenv --image=jpetazzo/httpenv --replicas=10
  ```

- Watch them being started:
  ```bash
  kubectl get pods -w
  ```

<!--
```wait httpenv-```
```keys ^C```
-->

]

The `jpetazzo/httpenv` image runs an HTTP server on port 8888.
<br/>
It serves its environment variables in JSON format.

The `-w` option "watches" events happening on the specified resources.

---

## Exposing our deployment

- We'll create a default `ClusterIP` service

.exercise[

- Expose the HTTP port of our server:
  ```bash
  kubectl expose deploy/httpenv --port 8888
  ```

- Look up which IP address was allocated:
  ```bash
  kubectl get svc
  ```

]

---

## Services are layer 4 constructs

- You can assign IP addresses to services, but they are still *layer 4*

  (i.e. a service is not an IP address; it's an IP address + protocol + port)

- This is caused by the current implementation of `kube-proxy`

  (it relies on mechanisms that don't support layer 3)

- As a result: you *have to* indicate the port number for your service
    
- Running services with arbitrary port (or port ranges) requires hacks

  (e.g. host networking mode)

---

## Testing our service

- We will now send a few HTTP requests to our pods

.exercise[

- Let's obtain the IP address that was allocated for our service, *programmatically:*
  ```bash
  IP=$(kubectl get svc httpenv -o go-template --template '{{ .spec.clusterIP }}')
  ```

<!--
```hide kubectl wait deploy httpenv --for condition=available```
-->

- Send a few requests:
  ```bash
  curl http://$IP:8888/
  ```

- Too much output? Filter it with `jq`:
  ```bash
  curl -s http://$IP:8888/ | jq .HOSTNAME
  ```

]

--

Try it a few times! Our requests are load balanced across multiple pods.

---

class: extra-details

## If we don't need a load balancer

- Sometimes, we want to access our scaled services directly:

  - if we want to save a tiny little bit of latency (typically less than 1ms)

  - if we need to connect over arbitrary ports (instead of a few fixed ones)

  - if we need to communicate over another protocol than UDP or TCP

  - if we want to decide how to balance the requests client-side

  - ...

- In that case, we can use a "headless service"

---

class: extra-details

## Headless services

- A headless service is obtained by setting the `clusterIP` field to `None`

  (Either with `--cluster-ip=None`, or by providing a custom YAML)

- As a result, the service doesn't have a virtual IP address

- Since there is no virtual IP address, there is no load balancer either

- CoreDNS will return the pods' IP addresses as multiple `A` records

- This gives us an easy way to discover all the replicas for a deployment

---

class: extra-details

## Services and endpoints

- A service has a number of "endpoints"

- Each endpoint is a host + port where the service is available

- The endpoints are maintained and updated automatically by Kubernetes

.exercise[

- Check the endpoints that Kubernetes has associated with our `httpenv` service:
  ```bash
  kubectl describe service httpenv
  ```

]

In the output, there will be a line starting with `Endpoints:`.

That line will list a bunch of addresses in `host:port` format.

---

class: extra-details

## Viewing endpoint details

- When we have many endpoints, our display commands truncate the list
  ```bash
  kubectl get endpoints
  ```

- If we want to see the full list, we can use one of the following commands:
  ```bash
  kubectl describe endpoints httpenv
  kubectl get endpoints httpenv -o yaml
  ```

- These commands will show us a list of IP addresses

- These IP addresses should match the addresses of the corresponding pods:
  ```bash
  kubectl get pods -l run=httpenv -o wide
  ```

---

class: extra-details

## `endpoints` not `endpoint`

- `endpoints` is the only resource that cannot be singular

```bash
$ kubectl get endpoint
error: the server doesn't have a resource type "endpoint"
```

- This is because the type itself is plural (unlike every other resource)

- There is no `endpoint` object: `type Endpoints struct`

- The type doesn't represent a single endpoint, but a list of endpoints
