# Exposing HTTP services with Ingress resources

- *Services* give us a way to access a pod or a set of pods

- Services can be exposed to the outside world:

  - with type `NodePort` (on a port >30000)

  - with type `LoadBalancer` (allocating an external load balancer)

- What about HTTP services?

  - how can we expose `webui`, `rng`, `hasher`?

  - the Kubernetes dashboard?

  - a new version of `webui`?

---

## Exposing HTTP services

- If we use `NodePort` services, clients have to specify port numbers

  (i.e. http://xxxxx:31234 instead of just http://xxxxx)

- `LoadBalancer` services are nice, but:

  - they are not available in all environments

  - they often carry an additional cost (e.g. they provision an ELB)

  - they require one extra step for DNS integration
    <br/>
    (waiting for the `LoadBalancer` to be provisioned; then adding it to DNS)

- We could build our own reverse proxy

---

## Building a custom reverse proxy

- There are many options available:

  Apache, HAProxy, Hipache, NGINX, Traefik, ...

  (look at [jpetazzo/aiguillage](https://github.com/jpetazzo/aiguillage) for a minimal reverse proxy configuration using NGINX)

- Most of these options require us to update/edit configuration files after each change

- Some of them can pick up virtual hosts and backends from a configuration store

- Wouldn't it be nice if this configuration could be managed with the Kubernetes API?

--

- Enter.red[¹] *Ingress* resources!

.footnote[.red[¹] Pun maybe intended.]

---

## Ingress resources

- Kubernetes API resource (`kubectl get ingress`/`ingresses`/`ing`)

- Designed to expose HTTP services

- Basic features:

  - load balancing
  - SSL termination
  - name-based virtual hosting

- Can also route to different services depending on:

  - URI path (e.g. `/api`→`api-service`, `/static`→`assets-service`)
  - Client headers, including cookies (for A/B testing, canary deployment...)
  - and more!

---

## Principle of operation

- Step 1: deploy an *ingress controller*

  - ingress controller = load balancer + control loop

  - the control loop watches over ingress resources, and configures the LB accordingly

- Step 2: set up DNS

  - associate DNS entries with the load balancer address

- Step 3: create *ingress resources*

  - the ingress controller picks up these resources and configures the LB

- Step 4: profit!

---

## Ingress in action

- We already have an nginx-ingress controller deployed

- For DNS, we have a wildcard set up pointing at our ingress LB

  - `*.ingress.workshop.paulczar.wtf`

- We will create ingress resources for various HTTP services

---

## Checking that nginx-ingress runs correctly

- If Traefik started correctly, we now have a web server listening on each node

.exercise[

- Check that nginx is serving 80/tcp:
  ```bash
  curl test.ingress.workshop.paulczar.wtf
  ```

]

We should get a `404 page not found` error.

This is normal: we haven't provided any ingress rule yet.

---

## Expose that webui

- Before we can enable the ingress, we need to create a service for the webui

.exercise[

  - create a service for the webui deployment
  ```bash
  kubectl expose deployment webui --port 80
  ```

]

---


## Setting up host-based routing ingress rules

- We are going to create an ingress rule for our webui

.exercise[
  - Write this to `~/workshop/ingress.yaml` and change the host prefix
]

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: webui
spec:
  rules:
  - host: user1.ingress.workshop.paulczar.wtf
    http:
      paths:
      - path: /
        backend:
          serviceName: webui
          servicePort: 80
```

---

## Creating our ingress resources

.exercise[
  - Apply the ingress manifest
  ```bash
  kubectl apply -f ~/workshop/ingress.yaml
  ```
]

--

```bash
$ curl user1.ingress.workshop.paulczar.wtf
Found. Redirecting to /index.html
```


---

## Using multiple ingress controllers

- You can have multiple ingress controllers active simultaneously

  (e.g. Traefik and NGINX)

- You can even have multiple instances of the same controller

  (e.g. one for internal, another for external traffic)

- The `kubernetes.io/ingress.class` annotation can be used to tell which one to use

- It's OK if multiple ingress controllers configure the same resource

  (it just means that the service will be accessible through multiple paths)

---

## Ingress: the good

- The traffic flows directly from the ingress load balancer to the backends

  - it doesn't need to go through the `ClusterIP`

  - in fact, we don't even need a `ClusterIP` (we can use a headless service)

- The load balancer can be outside of Kubernetes

  (as long as it has access to the cluster subnet)

- This allows the use of external (hardware, physical machines...) load balancers

- Annotations can encode special features

  (rate-limiting, A/B testing, session stickiness, etc.)

---

## Ingress: the bad

- Aforementioned "special features" are not standardized yet

- Some controllers will support them; some won't

- Even relatively common features (stripping a path prefix) can differ:

  - [traefik.ingress.kubernetes.io/rule-type: PathPrefixStrip](https://docs.traefik.io/user-guide/kubernetes/#path-based-routing)

  - [ingress.kubernetes.io/rewrite-target: /](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples/rewrite)

- This should eventually stabilize

  (remember that ingresses are currently `apiVersion: networking.k8s.io/v1beta1`)
