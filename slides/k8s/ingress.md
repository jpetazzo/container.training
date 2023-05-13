# Exposing HTTP services with Ingress resources

- Service = layer 4 (TCP, UDP, SCTP)

  - works with every TCP/UDP/SCTP protocol

  - doesn't "see" or interpret HTTP

- Ingress = layer 7 (HTTP)

  - only for HTTP

  - can route requests depending on URI or host header

  - can handle TLS

---

## Why should we use Ingress resources?

A few use-cases:

- URI routing (e.g. for single page apps)

  `/api` → service `api:5000`

  everything else → service `static:80`

- Cost optimization

  (using `LoadBalancer` services for everything would be expensive)

- Automatic handling of TLS certificates

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

  (one-time setup; typically done by cluster admin)

- Step 2: create *Ingress resources*

  - maps a domain and/or path to a Kubernetes Service

  - the controller watches ingress resources and sets up a LB

- Step 3: set up DNS (optional)

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

- We will create ingress resources for various HTTP services

- For DNS, we can use [nip.io](http://nip.io/)

  - `*.1.2.3.4.nip.io` resolves to `1.2.3.4`

---

## Classic ingress controller setup

- Ingress controller runs with a Deployment

  (with at least 2 replicas for redundancy)

- It is exposed with a `LoadBalancer` Service

- Typical for cloud-based clusters

- Also common when running or on-premises with [MetalLB] or [kube-vip]

[MetalLB]: https://metallb.org/
[kube-vip]: https://kube-vip.io/

---

## Alternate ingress controller setup

- Ingress controller runs with a DaemonSet

  (on bigger clusters, this can be coupled with a `nodeSelector`)

- It is exposed with `externalIPs`, `hostPort`, or `hostNetwork`

- Typical for on-premises clusters

  (where at least a set of nodes have a stable IP and high availability)

---

class: extra-details

## Why not a `NodePort` Service?

- Node ports are typically in the 30000-32767 range

- Web site users don't want to specify port numbers

  (e.g. "connect to https://blahblah.whatever:31550")

- Our ingress controller needs to actually be exposed on port 80

  (and 443 if we want to handle HTTPS)

---

class: extra-details

## Local clusters

- When running a local cluster, some extra steps might be necessary

- When using Docker-based clusters on Linux:

  *connect directly to the node's IP address (172.X.Y.Z)*

- When using Docker-based clusters with Docker Desktop:

  *set up port mapping (then connect to localhost:XYZ)*

- Generic scenario:

  *run `kubectl port-forward 8888:80` to the ingress controller*
  <br/>
  *(and then connect to `http://localhost:8888`)*

---

## Trying it out with Traefik

- We are going to run Traefik with a DaemonSet

  (there will be one instance of Traefik on every node of the cluster)

- The Pods will use `hostPort: 80`

- This means that we will be able to connect to any node of the cluster on port 80

---

## Running Traefik

- The [Traefik documentation][traefikdoc] recommends to use a Helm chart

- For simplicity, we're going to use a custom YAML manifest

- Our manifest will:

  - use a Daemon Set so that each node can accept connections

  - enable `hostPort: 80`

  - add a *toleration* so that Traefik also runs on all nodes

- We could do the same with the official [Helm chart][traefikchart]

[traefikdoc]: https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart
[traefikchart]: https://artifacthub.io/packages/helm/traefik/traefik

---

class: extra-details

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

- We provide a YAML file (@@LINK[k8s/traefik.yaml]) which contains:

  - a `traefik` Namespace

  - a `traefik` DaemonSet in that Namespace

  - RBAC rules allowing Traefik to watch the necessary API objects

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

## Traefik web UI

- Traefik provides a web dashboard

- With the current install method, it's listening on port 8080

.lab[

- Go to `http://node1:8080` (replacing `node1` with its IP address)

<!-- ```open http://node1:8080``` -->

]

---

## Setting up routing ingress rules

- We are going to use the `jpetazzo/color` image

- This image contains a simple static HTTP server on port 80

- We will run 3 deployments (`red`, `green`, `blue`)

- We will create 3 services (one for each deployment)

- Then we will create 3 ingress rules (one for each service)

- We will route requests to `/red`, `/green`, `/blue`

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

- Since Kubernetes 1.19, we can use `kubectl create ingress`

  (if you're running an older version of Kubernetes, **you must upgrade**)

.lab[

- Create the three ingress resources:
  ```bash
  kubectl create ingress red   --rule=/red=red:80
  kubectl create ingress green --rule=/green=green:80
  kubectl create ingress blue  --rule=/blue=blue:80
  ```

]

---

## Testing

- We should now be able to access `localhost/red`, `localhost/green`, etc.

.lab[

- Check that these routes work correctly:
  ```bash
  curl http://localhost/red
  curl http://localhost/green
  curl http://localhost/blue
  ```

]

---

## Accessing other URIs

- What happens if we try to access e.g. `/blue/hello`?

.lab[

- Retrieve the `ClusterIP` of Service `blue`:
  ```bash
  BLUE=$(kubectl get svc blue -o jsonpath={.spec.clusterIP})
  ```

- Check that the `blue` app serves `/hello`:
  ```bash
  curl $BLUE/hello
  ```

- See what happens if we try to access it through the Ingress:
  ```bash
  curl http://localhost/blue/hello
  ```

]

---

## Exact or prefix matches

- By default, ingress rules are *exact* matches

  (the request is routed only if the URI is exactly `/blue`)

- We can also ask a *prefix* match by adding a `*` to the rule

.lab[

- Create a prefix match rule for the `blue` service:
  ```bash
  kubectl create ingress bluestar --rule=/blue*:blue:80
  ```

- Check that it works:
  ```bash
  curl http://localhost/blue/hello
  ```

]

---

## Multiple rules per Ingress resource

- It is also possible to have multiple rules in a single resource

.lab[

- Create an Ingress resource with multiple rules:
  ```bash
  kubectl create ingress rgb \
      --rule=/red*=red:80 \
      --rule=/green*=green:80 \
      --rule=/blue*=blue:80
  ```

- Check that everything still works after deleting individual rules

]

---

## Using domain-based routing

- In the previous examples, we didn't use domain names

  (we routed solely based on the URI of the request)

- We are now going to show how to use domain-based routing

- We are going to assume that we have a domain name

  (for instance: `cloudnative.tld`)

- That domain name should be set up so that a few subdomains point to the ingress

  (for instance, `blue.cloudnative.tld`, `green.cloudnative.tld`...)

- For simplicity or flexibility, we can also use a wildcard record

---

## Setting up DNS

- To make our lives easier, we will use [nip.io](http://nip.io)

- Check out `http://red.A.B.C.D.nip.io`

  (replacing A.B.C.D with the IP address of `node1`)

- We should get the same `404 page not found` error

  (meaning that our DNS is "set up properly", so to speak!)

---

## Setting up name-based Ingress

.lab[

- Set the `$IPADDR` variable to our ingress controller address:
  ```bash
  IPADDR=`A.B.C.D`
  ```

- Create our Ingress resource:
  ```bash
  kubectl create ingress rgb-with-domain \
      --rule=red.$IPADDR.nip.io/*=red:80 \
      --rule=green.$IPADDR.nip.io/*=green:80 \
      --rule=blue.$IPADDR.nip.io/*=blue:80
  ```

- Test it out:
  ```bash
  curl http://red.$IPADDR.nip.io/hello
  ```

]

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

- It is now in beta (since v0.5.0, released in 2022)

???

:EN:- The Ingress resource
:FR:- La ressource *ingress*
