# Exercise — Ingress

- We want to expose a web app through an ingress controller

- This will require:

  - the web app itself (dockercoins, NGINX, whatever we want)

  - an ingress controller

  - a domain name (`use \*.nip.io` or `\*.localdev.me`)

  - an ingress resource

---

## Goal

- We want to be able to access the web app using a URL like:

  http://webapp.localdev.me

  *or*

  http://webapp.A.B.C.D.nip.io

  (where A.B.C.D is the IP address of one of our nodes)

---

## Hints

- For the ingress controller, we can use:

  - [ingress-nginx](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md)

  - the [Traefik Helm chart](https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart)

  - the container.training [Traefik DaemonSet](https://raw.githubusercontent.com/jpetazzo/container.training/main/k8s/traefik-v2.yaml)

- If our cluster supports LoadBalancer Services: easy

  (nothing special to do)

- For local clusters, things can be more difficult; two options:

  - map localhost:80 to e.g. a NodePort service, and use `\*.localdev.me`

  - use hostNetwork, or ExternalIP, and use `\*.nip.io`
