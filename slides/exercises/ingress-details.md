# Exercise - Ingress

- We want to expose a web app through an ingress controller

- This will require:

  - the web app itself (dockercoins, NGINX, whatever we want)

  - an ingress controller (we suggest Traefik)

  - a domain name (`use \*.nip.io` or `\*.localdev.me`)

  - an ingress resource

---

## Goal

- We want to be able to access the web app using an URL like:

  http://webapp.localdev.me

  *or*

  http://webapp.A.B.C.D.nip.io

  (where A.B.C.D is the IP address of one of our nodes)

---

## Hints

- Traefik can be installed with Helm

  (it can be found on the Artifact Hub)

- If using Kubernetes 1.22+, make sure to use Traefik 2.5+

- If our cluster supports LoadBalancer Services: easy

  (nothing special to do)

- For local clusters, things can be more difficult; two options:

  - map localhost:80 to e.g. a NodePort service, and use `\*.localdev.me`

  - use hostNetwork, or ExternalIP, and use `\*.nip.io`
