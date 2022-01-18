# Exposing HTTP services with Ingress resources

- HTTP services are typically exposed on port 80

  (and 443 for HTTPS)

- `NodePort` services are great, but they are *not* on port 80

  (by default, they use port range 30000-32767)

- How can we get *many* HTTP services on port 80? 🤔

---

## Various ways to expose something on port 80

- Service with `type: LoadBalancer`

  *costs a little bit of money; not always available*

- Service with one (or multiple) `ExternalIP`

  *requires public nodes; limited by number of nodes*

- Service with `hostPort` or `hostNetwork`

  *same limitations as `ExternalIP`; even harder to manage*

- Ingress resources

  *addresses all these limitations, yay!*

---

## `LoadBalancer` vs `Ingress`

- Service with `type: LoadBalancer`

  - requires a particular controller (e.g. CCM, MetalLB)
  - if TLS is desired, it has to be implemented by the app
  - works for any TCP protocol (not just HTTP)
  - doesn't interpret the HTTP protocol (no fancy routing)
  - costs a bit of money for each service

- Ingress

  - requires an ingress controller
  - can implement TLS transparently for the app
  - only supports HTTP
  - can do content-based routing (e.g. per URI)
  - lower cost per service
    <br/>(exact pricing depends on provider's model)

---

## Ingress resources

- Kubernetes API resource (`kubectl get ingress`/`ingresses`/`ing`)

- Designed to expose HTTP services

- Requires an *ingress controller*

  (otherwise, resources can be created, but nothing happens)

- Some ingress controllers are based on existing load balancers

  (HAProxy, NGINX...)

- Some are standalone, and sometimes designed for Kubernetes

  (Contour, Traefik...)

- Note: there is no "default" or "official" ingress controller!

---

## Ingress standard features

- Load balancing

- SSL termination

- Name-based virtual hosting

- URI routing

  (e.g. `/api`→`api-service`, `/static`→`assets-service`)

---

## Ingress extended features

(Not always supported; supported through annotations, CRDs, etc.)

- Routing with other headers or cookies

- A/B testing

- Canary deployment

- etc.

---

## Principle of operation

- Step 1: deploy an *ingress controller*

  (one-time setup)

- Step 2: create *Ingress resources*

  - maps a domain and/or path to a Kubernetes Service

  - the controller watches ingress resources and sets up a LB

- Step 3: set up DNS

  - associate DNS entries with the load balancer address

---

class: extra-details

## Special cases

- GKE has "[GKE Ingress]", a custom ingress controller

  (enabled by default)

- EKS has "AWS ALB Ingress Controller" as well

  (not enabled by default, requires extra setup)

- They leverage cloud-specific HTTP load balancers

  (GCP HTTP LB, AWS ALB)

- They typically a cost *per ingress resource*

[GKE Ingress]: https://cloud.google.com/kubernetes-engine/docs/concepts/ingress

---

class: extra-details

## Single or multiple LoadBalancer

- Most ingress controllers will create a LoadBalancer Service

  (and will receive all HTTP/HTTPS traffic through it)

- We need to point our DNS entries to the IP address of that LB

- Some rare ingress controllers will allocate one LB per ingress resource

  (example: the GKE Ingress and ALB Ingress mentioned previously)

- This leads to increased costs

- Note that it's possible to have multiple "rules" per ingress resource

  (this will reduce costs but may be less convenient to manage)

---

## Ingress in action

- We will deploy the Traefik ingress controller

  - this is an arbitrary choice

  - maybe motivated by the fact that Traefik releases are named after cheeses

- For DNS, we will use [nip.io](http://nip.io/)

  - `*.1.2.3.4.nip.io` resolves to `1.2.3.4`

- We will create ingress resources for various HTTP services

---

## Deploying pods listening on port 80

- We want our ingress load balancer to be available on port 80

- The best way to do that would be with a `LoadBalancer` service

  ... but it requires support from the underlying infrastructure

- Instead, we are going to use the `hostNetwork` mode on the Traefik pods

- Let's see what this `hostNetwork` mode is about ...

---

## Without `hostNetwork`

- Normally, each pod gets its own *network namespace*

  (sometimes called sandbox or network sandbox)

- An IP address is assigned to the pod

- This IP address is routed/connected to the cluster network

- All containers of that pod are sharing that network namespace

  (and therefore using the same IP address)

---

## With `hostNetwork: true`

- No network namespace gets created

- The pod is using the network namespace of the host

- It "sees" (and can use) the interfaces (and IP addresses) of the host

- The pod can receive outside traffic directly, on any port

- Downside: with most network plugins, network policies won't work for that pod

  - most network policies work at the IP address level

  - filtering that pod = filtering traffic from the node

---

class: extra-details

## Other techniques to expose port 80

- We could use pods specifying `hostPort: 80` 

  ... but with most CNI plugins, this [doesn't work or requires additional setup](https://github.com/kubernetes/kubernetes/issues/23920)

- We could use a `NodePort` service

  ... but that requires [changing the `--service-node-port-range` flag in the API server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)

- We could create a service with an external IP

  ... this would work, but would require a few extra steps

  (figuring out the IP address and adding it to the service)

---

## Running Traefik

- The [Traefik documentation][traefikdoc] recommends to use a Helm chart

- For simplicity, we're going to use a custom YAML manifest

- Our manifest will:

  - use a Daemon Set so that each node can accept connections

  - enable `hostNetwork`

  - add a *toleration* so that Traefik also runs on all nodes

- We could do the same with the official [Helm chart][traefikchart]

[traefikdoc]: https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart
[traefikchart]: https://artifacthub.io/packages/helm/traefik/traefik

---

## Taints and tolerations

- A *taint* is an attribute added to a node

- It prevents pods from running on the node

- ... Unless they have a matching *toleration*

- When deploying with `kubeadm`:

  - a taint is placed on the node dedicated to the control plane

  - the pods running the control plane have a matching toleration

---

class: extra-details

## Checking taints on our nodes

.lab[

- Check our nodes specs:
  ```bash
  kubectl get node node1 -o json | jq .spec
  kubectl get node node2 -o json | jq .spec
  ```

]

We should see a result only for `node1` (the one with the control plane):

```json
  "taints": [
    {
      "effect": "NoSchedule",
      "key": "node-role.kubernetes.io/master"
    }
  ]
```

---

class: extra-details

## Understanding a taint

- The `key` can be interpreted as:

  - a reservation for a special set of pods
    <br/>
    (here, this means "this node is reserved for the control plane")

  - an error condition on the node
    <br/>
    (for instance: "disk full," do not start new pods here!)

- The `effect` can be:

  - `NoSchedule` (don't run new pods here)

  - `PreferNoSchedule` (try not to run new pods here)

  - `NoExecute` (don't run new pods and evict running pods)

---

class: extra-details

## Checking tolerations on the control plane

.lab[

- Check tolerations for CoreDNS:
  ```bash
  kubectl -n kube-system get deployments coredns -o json |
          jq .spec.template.spec.tolerations
  ```

]

The result should include:
```json
  {
    "effect": "NoSchedule",
    "key": "node-role.kubernetes.io/master"
  }
```

It means: "bypass the exact taint that we saw earlier on `node1`."

---

class: extra-details

## Special tolerations

.lab[

- Check tolerations on `kube-proxy`:
  ```bash
  kubectl -n kube-system get ds kube-proxy -o json | 
          jq .spec.template.spec.tolerations
  ```

]

The result should include:
```json
  {
    "operator": "Exists"
  }
```

This one is a special case that means "ignore all taints and run anyway."

---

## Running Traefik on our cluster

- We provide a YAML file (`k8s/traefik.yaml`) which is essentially the sum of:

  - [Traefik's Daemon Set resources](https://github.com/containous/traefik/blob/v1.7/examples/k8s/traefik-ds.yaml) (patched with `hostNetwork` and tolerations)

  - [Traefik's RBAC rules](https://github.com/containous/traefik/blob/v1.7/examples/k8s/traefik-rbac.yaml) allowing it to watch necessary API objects

.lab[

- Apply the YAML:
  ```bash
  kubectl apply -f ~/container.training/k8s/traefik.yaml
  ```

]

---

## Checking that Traefik runs correctly

- If Traefik started correctly, we now have a web server listening on each node

.lab[

- Check that Traefik is serving 80/tcp:
  ```bash
  curl localhost
  ```

]

We should get a `404 page not found` error.

This is normal: we haven't provided any ingress rule yet.

---

## Setting up DNS

- To make our lives easier, we will use [nip.io](http://nip.io)

- Check out `http://red.A.B.C.D.nip.io`

  (replacing A.B.C.D with the IP address of `node1`)

- We should get the same `404 page not found` error

  (meaning that our DNS is "set up properly", so to speak!)

---

## Traefik web UI

- Traefik provides a web dashboard

- With the current install method, it's listening on port 8080

.lab[

- Go to `http://node1:8080` (replacing `node1` with its IP address)

<!-- ```open http://node1:8080``` -->

]

---

## Setting up host-based routing ingress rules

- We are going to use the `jpetazzo/color` image

- This image contains a simple static HTTP server on port 80

- We will run 3 deployments (`red`, `green`, `blue`)

- We will create 3 services (one for each deployment)

- Then we will create 3 ingress rules (one for each service)

- We will route `<color>.A.B.C.D.nip.io` to the corresponding deployment

---

## Running colorful web servers

.lab[

- Run all three deployments:
  ```bash
  kubectl create deployment red   --image=jpetazzo/color
  kubectl create deployment green --image=jpetazzo/color
  kubectl create deployment blue  --image=jpetazzo/color
  ```

- Create a service for each of them:
  ```bash
  kubectl expose deployment red   --port=80
  kubectl expose deployment green --port=80
  kubectl expose deployment blue  --port=80
  ```

]

---

## Creating ingress resources

- Before Kubernetes 1.19, we must use YAML manifests

  (see example on next slide)

- Since Kubernetes 1.19, we can use `kubectl create ingress`

  ```bash
  kubectl create ingress red \
      --rule=red.`A.B.C.D`.nip.io/*=red:80
  ```

- We can specify multiple rules per resource

  ```bash
  kubectl create ingress rgb \
      --rule=red.`A.B.C.D`.nip.io/*=red:80 \
      --rule=green.`A.B.C.D`.nip.io/*=green:80 \
      --rule=blue.`A.B.C.D`.nip.io/*=blue:80
  ```

---

## Pay attention to the `*`!

- The `*` is important:

  ```
  --rule=red.A.B.C.D.nip.io/`*`=red:80
  ```

- It means "all URIs below that path"

- Without the `*`, it means "only that exact path"

  (if we omit it, requests for e.g. `red.A.B.C.D.nip.io/hello` will 404)

---

## Ingress resources in YAML

Here is a minimal host-based ingress resource:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: red
spec:
  rules:
  - host: red.`A.B.C.D`.nip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: red
          servicePort: 80

```

(It is in `k8s/ingress.yaml`.)

---

class: extra-details

## Ingress API version

- The YAML on the previous slide uses `apiVersion: networking.k8s.io/v1beta1`

- Starting with Kubernetes 1.19, `networking.k8s.io/v1` is available

- However, with Kubernetes 1.19 (and later), we can use `kubectl create ingress`

- We chose to keep an "old" (deprecated!) YAML example for folks still using older versions of Kubernetes

- If we want to see "modern" YAML, we can use `-o yaml --dry-run=client`:

  ```bash
  kubectl create ingress red -o yaml --dry-run=client \
      --rule=red.`A.B.C.D`.nip.io/*=red:80

  ```

---

## Creating ingress resources

- Create the ingress resources with `kubectl create ingress`

  (or use the YAML manifests if using Kubernetes 1.18 or older)

- Make sure to update the hostnames!

- Check that you can connect to the exposed web apps

---

class: extra-details

## Using multiple ingress controllers

- You can have multiple ingress controllers active simultaneously

  (e.g. Traefik and NGINX)

- You can even have multiple instances of the same controller

  (e.g. one for internal, another for external traffic)

- To indicate which ingress controller should be used by a given Ingress resouce:

  - before Kubernetes 1.18, use the `kubernetes.io/ingress.class` annotation

  - since Kubernetes 1.18, use the `ingressClassName` field
    <br/>
    (which should refer to an existing `IngressClass` resource)

---

## Ingress shortcomings

- A lot of things have been left out of the Ingress v1 spec

  (routing requests according to weight, cookies, across namespaces...)

- Example: stripping path prefixes

  - NGINX: [nginx.ingress.kubernetes.io/rewrite-target: /](https://github.com/kubernetes/ingress-nginx/blob/main/docs/examples/rewrite/README.md)

  - Traefik v1: [traefik.ingress.kubernetes.io/rule-type: PathPrefixStrip](https://doc.traefik.io/traefik/migration/v1-to-v2/#strip-and-rewrite-path-prefixes)

  - Traefik v2: [requires a CRD](https://doc.traefik.io/traefik/migration/v1-to-v2/#strip-and-rewrite-path-prefixes)

---

## Ingress in the future

- The [Gateway API SIG](https://gateway-api.sigs.k8s.io/) might be the future of Ingress

- It proposes new resources:

 GatewayClass, Gateway, HTTPRoute, TCPRoute...

- It is still in alpha stage

---

## Vendor-specific example

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

???

:EN:- The Ingress resource
:FR:- La ressource *ingress*
