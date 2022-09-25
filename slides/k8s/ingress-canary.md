## Ingress and canary releases

- Let's see how to implement *canary releases*

- The example here will use Traefik v1

  (which is obsolete)

- It won't work on your Kubernetes cluster!

  (unless you're running an oooooold version of Kubernetes)

  (and an equally oooooooold version of Traefik)

- We've left it here just as an example!

---

## Canary releases

- A *canary release* (or canary launch or canary deployment) is a release that will process only a small fraction of the workload

- After deploying the canary, we compare its metrics to the normal release

- If the metrics look good, the canary will progressively receive more traffic

  (until it gets 100% and becomes the new normal release)

- If the metrics aren't good, the canary is automatically removed

- When we deploy a bad release, only a tiny fraction of traffic is affected

---

## Various ways to implement canary

- Example 1: canary for a microservice

  - 1% of all requests (sampled randomly) are sent to the canary
  - the remaining 99% are sent to the normal release

- Example 2: canary for a web app

  - 1% of users are sent to the canary web site
  - the remaining 99% are sent to the normal release

- Example 3: canary for shipping physical goods

  - 1% of orders are shipped with the canary process
  - the remaining 99% are shipped with the normal process

- We're going to implement example 1 (per-request routing)

---

## Canary releases with Traefik v1

- We need to deploy the canary and expose it with a separate service

- Then, in the Ingress resource, we need:

  - multiple `paths` entries (one for each service, canary and normal)

  - an extra annotation indicating the weight of each service

- If we want, we can send requests to more than 2 services

---

## The Ingress resource

.small[
```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: rgb
  annotations:
    traefik.ingress.kubernetes.io/service-weights: |
      red: 50%
      green: 25%
      blue: 25%
spec:
  rules:
  - host: rgb.`A.B.C.D`.nip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: red
          servicePort: 80
      - path: /
        backend:
          serviceName: green
          servicePort: 80
      - path: /
        backend:
          serviceName: blue
          servicePort: 80
```
]

---

class: extra-details

## Other ingress controllers

*Just to illustrate how different things are ...*

- With the NGINX ingress controller:

  - define two ingress ressources
    <br/>
    (specifying rules with the same host+path)

  - add `nginx.ingress.kubernetes.io/canary` annotations on each


- With Linkerd2:

  - define two services

  - define an extra service for the weighted aggregate of the two

  - define a TrafficSplit (this is a CRD introduced by the SMI spec)

---

class: extra-details

## We need more than that

What we saw is just one of the multiple building blocks that we need to achieve a canary release.

We also need:

- metrics (latency, performance ...) for our releases

- automation to alter canary weights

  (increase canary weight if metrics look good; decrease otherwise)

- a mechanism to manage the lifecycle of the canary releases

  (create them, promote them, delete them ...)

For inspiration, check [flagger by Weave](https://github.com/weaveworks/flagger).
