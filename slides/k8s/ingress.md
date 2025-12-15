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

  - requires an Ingress Controller
  - can implement TLS transparently for the app
  - only supports HTTP
  - can do content-based routing (e.g. per URI)
  - lower cost per service
    <br/>(exact pricing depends on provider's model)

---

## Ingress resources

- Kubernetes API resource (`kubectl get ingress`/`ingresses`/`ing`)

- Designed to expose HTTP services

- Requires an *Ingress Controller*

  (otherwise, resources can be created, but nothing happens)

- Some Kubernetes distributions automatically install an Ingress Controller

  (or they give that option as an easy "on/off" switch at install time)

- It's relatively rare, though, because Ingress Controllers aren't "one size fits all"

---

## Checking if we have an Ingress Controller

- A modern Ingress Controller will create an IngressClass resource

- We can check simply by running `kubectl get ingressclasses`

- Example:
  ```shell
    $ kubectl get ingressclasses
    NAME      CONTROLLER                      PARAMETERS   AGE
    traefik   traefik.io/ingress-controller   <none>       139m  
  ```

- It's also possible to have an IngressClass without a working Ingress Controller

  (e.g. if the controller is broken, or has been partially uninstalled...)

---

## A taxonomy of Ingress Controllers

- Some Ingress Controllers are based on existing load balancers

  (HAProxy, NGINX...)

- Some are standalone, and sometimes designed for Kubernetes

  (Contour, Traefik...)

- Some are proprietary to a specific hardware or cloud vendor

  (GKE Ingress, AWS ALB Ingress)

- Note: there is no "default" or "official" Ingress Controller!

---

class: extra-details

## Details about these proprietary controllers

- GKE has "[GKE Ingress]", a custom Ingress Controller

  (enabled by default but [does not use IngressClass][gke-ingressclass])

- EKS has "AWS ALB Ingress Controller" as well

  (not enabled by default, requires extra setup)

- They leverage cloud-specific HTTP load balancers

  (GCP HTTP LB, AWS ALB)

- They typically carry a cost *per ingress resource*

[GKE Ingress]: https://cloud.google.com/kubernetes-engine/docs/concepts/ingress
[gke-ingressclass]: https://docs.cloud.google.com/kubernetes-engine/docs/concepts/ingress#deprecated_annotation

---

class: extra-details

## Single or multiple LoadBalancer

- Most Ingress Controllers will create a LoadBalancer Service

  (and will receive all HTTP/HTTPS traffic through it)

- We need to point our DNS entries to the IP address of that LB

- Some rare Ingress Controllers will allocate one LB per ingress resource

  (example: the GKE Ingress and ALB Ingress mentioned previously)

- This leads to increased costs

- Note that it's possible to have multiple "rules" per ingress resource

  (this will reduce costs but may be less convenient to manage)

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

*Supporting these features in a standard, vendor-independent way, is
one of the goals of the Gateway API. (More on that at the end of this section!)*

---

## Principle of operation

- Step 1: deploy an *Ingress Controller*

  (one-time setup; typically done by cluster admin)

- Step 2: create *Ingress resources*

  - maps a domain and/or path to a Kubernetes Service

  - the controller watches Ingress resources and sets up a LB

- Step 3: set up DNS (optional)

  - associate DNS entries with the load balancer address

  - this can be automated with [ExternalDNS]

[ExternalDNS]: https://github.com/kubernetes-sigs/external-dns

---

## Ingress in action

- We're going to deploy an Ingress Controller

  (unless our cluster already has one that we can use)

- Then, we will create ingress resources for various HTTP services

- We'll demonstrate DNS integration as well

- If you don't have a domain name for this part, you can use [nip.io]

  (`*.1.2.3.4.nip.io` resolves to `1.2.3.4`)

---

## Deploying the Ingress Controller

- Many variations are possible, depending on:

  - which Ingress Controller we pick

  - whether `LoadBalancer` Services are available or not

  - the deployment tool we want to use (Helm, plain YAML...)

- If you're attending a live class, we're going to take a shortcut

  (with a ready-to-use manifest optimized for the clusters we use in class)

- Otherwise, check the section dedicated to Ingress Controller setup first

---

## If you're attending a live class...

- Each student is assigned a pre-configured cluster

  (sometimes, multiple clusters, to demonstrate different scenarios)

- We have prepared a YAML manifest that will take care of setting up Traefik for you

.lab[

- Install Traefik on your cluster:
  ```bash
  kubectl apply -f ~/container.training/k8s/traefik.yml
  ```

]

- Note: this YAML manifest is only suitable for live class clusters!

---

class: extra-details

## What's about this manifest?

- It runs Traefik with a DaemonSet

  (there will be one instance of Traefik on every node of the cluster)

- The Pods will use `hostPort: 80`

- This means that we will be able to connect to any node of the cluster on port 80

- It also includes a *toleration* to make sure Traefik runs on every Node

  (including the control plane Node)

---

## Creating Ingress resources

- We are going to use the `jpetazzo/color` image

- This image contains a simple static HTTP server on port 80

- We will run a Deployment, e.g. `blue`

- We will expose that Deployment with a Service

- And create an Ingress for that Service

---

## Deploying the `blue` app

- Nothing special here; we're just creating a Deployment and a Service

.lab[

- Create the Deployment:
  ```bash
  kubectl create deployment blue --image=jpetazzo/color
  ```

- Expose it with a Service:
  ```bash
  kubectl expose deployment blue --port=80
  ```

]

---

## Creating Ingress resources

- There is a convenient helper command, `kubectl create ingress`

  (available since Kubernetes 1.19; before that, the only way was to use YAML manifests)

- An Ingress resource can contain one or multiple "rules"

.lab[

- Create an Ingress with a single rule:
  ```bash
  kubectl create ingress blue --rule=/blue=blue:80
  ```
]

`/blue` = HTTP path that the Ingress should use

`blue:80` = Service name + port where requests should be sent

---

## Testing our new Ingress

- We need to know to which IP address to connect

- If you're attending a live class; of if you installed your Ingress Controller with a DaemonSet and `hostPort` or `hostNetwork`:

  *use the IP address of any of the nodes of your cluster*

- If you installed your Ingress Controller with a `LoadBalancer` Service:

  *use the EXTERNAL-IP of the Service*

- If you're using a local dev cluster:

  *it depends; we suggest `kubectl port-forward` and then use `localhost`*

---

## Testing our new Ingress

- Connect to `http://<IP address>/blue`

- We should see a reply from the `blue` Deployment

---

## Using domain names

- With Ingress, we can use what is often called "name-based virtual hosting"

- This lets us host multiple web apps on a single IP address

- All we need is to used a different domain name for each web app

  (e.g.: `blue.example.com`, `green.example.com`, `red.example.com`...)

- We could use a real domain name, or, for simplicity, [nip.io]

- In the next steps, we'll assume that our Ingress controller uses IP address `A.B.C.D`

  (make sure to substitute accordingly!)

---

## Before creating the Ingress

- We will make the `blue` Deployment available at the URL http://blue.A.B.C.D.nip.io

.lab[

- Let's check what happens if we connect to that address right now:
  ```bash
  curl http://blue.A.B.C.D.nip.io
  ```

]

- If we're using Traefik, it will give us a very terse `404 not found` error

  (that's expected!)

---

## Creating the Ingress

- This will be very similar to the Ingress that we created earlier

- But we're going to add a domain name in the rule

.lab[

- Create the Ingress:
  ```bash
  kubectl create ingress blue-with-domain --rule=blue.A.B.C.D.nip.io/=blue:80
  ```

- Test it:
  ```bash
  curl http://blue.A.B.C.D.nip.io
  ```

]

- We should see a response from the `blue` Deployment

---

## Exact or prefix matches

- By default, Ingress rules are *exact* matches

  (the request is routed only for the specified URL)

.lab[

- Confirm that only `/` routes to the `blue` app:
  ```bash
  curl http://blue.A.B.C.D.nip.io         # works
  curl http://blue.A.B.C.D.nip.io/hello   # does not work
  ```

]

- How do we change that?

---

## Specifying a prefix match

- If a rule ends with `*`, it will be interpreted as a prefix match

.lab[

- Create a prefix match rule for the `blue` service:
  ```bash
  kubectl create ingress blue-with-prefix --rule=blue.A.B.C.D.nip.io/*=blue:80
  ```

- Check that it works:
  ```bash
  curl http://blue.A.B.C.D.nip.io/hello
  ```

]

---

## What do Ingress manifests look like?

- Let's have a look at the manifests generated by `kubectl create ingress`!

- We'll use `-o yaml` to display the YAML generated by `kubectl`

- And `--dry-run=client` to instruct `kubectl` to skip resource creation
 
.lab[

- Generate and display a few manifests:
  ```bash
    kubectl create ingress -o yaml --dry-run=client \
            exact-route --rule=/blue=blue:80

    kubectl create ingress -o yaml --dry-run=client \
            with-a-domain --rule=blue.test/=blue:80

    kubectl create ingress -o yaml --dry-run=client \
            now-with-a-prefix --rule=blue.test/*=blue:80
  ```

]

---

## Multiple rules per Ingress resource

- It is also possible to have multiple rules in a single Ingress resource

- Let's see what that looks like, too!

.lab[

- Show the manifest for an Ingress resource with multiple rules:
  ```bash
    kubectl create ingress -o yaml --dry-run=client rgb \
            --rule=/red*=red:80 \
            --rule=/green*=green:80 \
            --rule=/blue*=blue:80
  ```

]

---

class: extra-details

## Using multiple Ingress Controllers

- You can have multiple Ingress Controllers active simultaneously

  (e.g. Traefik and NGINX)

- You can even have multiple instances of the same controller

  (e.g. one for internal, another for external traffic)

- To indicate which Ingress Controller should be used by a given Ingress resouce:

  - before Kubernetes 1.18, use the `kubernetes.io/ingress.class` annotation

  - since Kubernetes 1.18, use the `ingressClassName` field
    <br/>
    (which should refer to an existing `IngressClass` resource)

---

## Ingress shortcomings

- A lot of things have been left out of the Ingress v1 spec

  (e.g.: routing requests according to weight, cookies, across namespaces...)

- Most Ingress Controllers have vendor-specific ways to address these shortcomings

- But since they're vendor-specific, migrations become more complex

- Example: stripping path prefixes

  - NGINX: [nginx.ingress.kubernetes.io/rewrite-target: /](https://github.com/kubernetes/ingress-nginx/blob/main/docs/examples/rewrite/README.md)

  - Traefik v1: [traefik.ingress.kubernetes.io/rule-type: PathPrefixStrip](https://doc.traefik.io/traefik/migration/v1-to-v2/#strip-and-rewrite-path-prefixes)

  - Traefik v2: [requires a CRD](https://doc.traefik.io/traefik/migration/v1-to-v2/#strip-and-rewrite-path-prefixes)

---

## A word about Ingress NGINX

- There are two Ingress Controllers based on NGINX (both open source)

- [F5 NGINX Ingress Controller][f5-nginx] aka "NGINX Ingress" ([GitHub repo][f5-nginx-repo], [docs][f5-nginx-docs])

  - developed and maintained by F5 (company that acquired NGINX in 2019)

  - supports vendor-specific CRDs like [VirtualServer and VirtualServerRoute][f5-nginx-crds]

- Ingress NGINX Controller aka "Ingress NGINX" ([GitHub repo][k8s-nginx-repo], [docs][k8s-nginx-docs])

  - one of the earliest Kubernetes Ingress Controllers

  - developed by the community

  - **no longer under active development; maintenance will stop in March 2026**
    (check the [announcement][k8s-nginx-announcement])

[f5-nginx]: https://docs.nginx.com/nginx-ingress-controller/
[f5-nginx-docs]: https://docs.nginx.com/nginx-ingress-controller
[f5-nginx-repo]: https://github.com/nginx/kubernetes-ingress
[f5-nginx-crds]: https://docs.nginx.com/nginx-ingress-controller/configuration/virtualserver-and-virtualserverroute-resources/
[k8s-nginx-docs]: https://kubernetes.github.io/ingress-nginx/
[k8s-nginx-repo]: https://github.com/kubernetes/ingress-nginx
[k8s-nginx-announcement]: https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/

---

## A word about software sustainability

- From the Ingress NGINX retirement announcement:

  *Despite the project’s popularity among users, Ingress NGINX has always struggled with insufficient or barely-sufficient maintainership. For years, the project has had only one or two people doing development work, on their own time, after work hours and on weekends.*

--

- If your production, mission-critical workloads depend on open source software:

  *what happens if the maintainers throw the towel?*

--

- If your production, mission-critical workloads depend on commercial software:

  *what happens if the the company behind it goes out of business?*

  *what happens if they drastically change their business model or [pricing][vmware1] [structure][vmware2]?*

[vmware1]: https://www.theregister.com/2025/05/22/euro_cloud_body_ecco_says_broadcom_licensing_unfair/
[vmware2]: https://www.ciodive.com/news/att-broadcom-vmware-price-hikes-court-battle/728603/

---

## Ingress in the future

- The [Gateway API SIG](https://gateway-api.sigs.k8s.io/) is probably be the future of Ingress

- It proposes new resources:

 GatewayClass, Gateway, HTTPRoute, TCPRoute...

- It now has feature parity with Ingress

  (=it can be used instead of Ingress resources; or in addition to them)

- It is, however, more complex to set up and operate

  (at least for now!)

???

[nip.io]: http://nip.io

:EN:- The Ingress resource
:FR:- La ressource *ingress*
