# Exercise — Setting up HTTP Ingress with Helm

In this lab, we want to leverage multiple skills:

- installing (and configuring!) apps with Helm charts

- exposing a simple app through Ingress or HTTPRoute

- leveraging DaemonSets, taints, tolerations, node selectors

**⚠️ Please read all instructions until the "GO!" slide!**

---

## Goal

- Deploy an Ingress or Gateway API controller

  (e.g.: Traefik or HAProxy, using their official Helm charts)

- Deploy a couple of apps and expose them with a domain name

  (e.g.: `jpetazzo/color` and the [juice-shop] demo app)

- Do that on multiple clusters with different topologies

  (`kubeadm` cluster; managed cluster; local KinD cluster)

- Bonus: set up TLS with cert-manager and Let's Encrypt

  (will require a "real" domain name!)

[juice-shop]: https://artifacthub.io/packages/helm/securecodebox/juice-shop

---

## Variations

There are many multiple choices available in this lab.

Try to complete at least one path; but feel free to experiment with other options too!

---

## Which environment?

- Managed cluster (difficulty: low)

  easier, because it has `LoadBalancer` services
  <br/>
  (and most Helm charts assume that `LoadBalancer` services are available)

- `kubeadm` cluster (difficulty: medium)

  requires to switch to a combination of `hostPort` / `DaemonSet`

- Local KinD cluster (difficulty: hard)

  actually not *that* hard, but you need to set up port mapping correctly

  only do this if you already have a working KinD install!

---

## Which API?

- Ingress (difficulty: easy)

  legacy (but still supported); much simpler to deploy/operate

- Gateway API HTTPRoute, TLSRoute (difficulty: medium)

  new; hopefully future-proof; support is uneven across products

- Gateway API TCPRoute (difficulty: hard)

  experimental; requires even more tinkering

- Vendor-specific

---

## Which controller?

- Traefik (difficulty: medium)

  better Kubernetes integration (especially for Gateway API!)

- HAProxy Ingress (difficulty: hard)

  supports Ingress and TCPRoute, but doesn't supportessential Gateway API features

- HAProxy Unified Gateway (difficulty: hard)

  supports Gateway API more comprehensively, but doesn't support Ingress

---

## Which domain name?

- `<appname>.A.B.C.D.nip.io` (difficulty: easy)

  pros: works anywhere in a pinch!

  cons: not "pretty"; may not work for Let's Encrypt; can be a SPOF

- `<appname>.<customdomain.TLD>` (difficulty: easy/hard)

  easy if a domain has already been set up for you; harder otherwise

  use that on the `kubeadm` cluster!

- `<appname>.localtest.me`

  use this for the KinD cluster

---

## Where to start?

- Pick a cluster (e.g.: `kubeadm cluster`)

- Pick a controller (e.g.: Traefik)

- Install controller on cluster

- Install a demo app (e.g.: `jpetazzo/color`)

- Expose demo app on a domain name with Ingress resource

- Script the whole setup

  (make sure script is idempotent!)

---

## Where to go next?

- Expose demo app with an HTTPRoute

- Install and expose juice-shop app

- Replicate the whole setup on another cluster

---

## Bonus goals

- Obtain a valid TLS cert for our web apps, with cert-manager + Let's Encrypt

  (this requires a real domain name; use the `kubeadm` cluster with the provided domain!)

- Deploy the dockercoins app

  - expose webui, rng, hasher, with Ingress / HTTPRoute

  - expose redis with a TLSRoute

  - try a TCPRoute (experimental!)

Note: for the TLSRoute, you can use a valid cert or a manual, self-signed one.

---

class: title

Go!

![Go!](images/running-mario.gif)