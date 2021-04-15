# DNS, Ingress, Metrics

- We got a basic app up and running

- We accessed it over a raw IP address

- Can we do better?

  (i.e. access it with a domain name!)

- How much resources is it using?

---

## DNS

- We'd like to associate a fancy name to that LoadBalancer Service

  (e.g. `nginx.cloudnative.party` → `A.B.C.D`)

  - option 1: manually add a DNS record

  - option 2: find a way to create DNS records automatically

- We will install ExternalDNS to automate DNS records creatoin

- ExternalDNS supports Linode DNS and dozens of other providers

---

## Ingress

- What if we have multiple web services to expose?

- We could create one LoadBalancer Service for each of them

- This would create a lot of cloud load balancers

  (and they typically incur a cost, even if it's a small one)

- Instead, we can use an *Ingress Controller*

- Ingress Controller = HTTP load balancer / reverse proxy

- Put all our HTTP services behind a single LoadBalancer Service

- Can also do fancy "content-based" routing (using headers, request path...)

- We will install Traefik as our Ingress Controller

---

## Metrics

- How much resources are we using right now?

- When will we need to scale up our cluster?

- We need metrics!

- We're going to install the *metrics server*

- It's a very basic metrics system

  (no retention, no graphs, no alerting...)

- But it's lightweight, and it is used internally by Kubernetes for autoscaling

---

## What's next

- We're going to install all these components

- Very often, things can be installed with a simple YAML file

- Very often, that YAML file needs to be customized a little bit

  (add command-line parameters, provide API tokens...)

- Instead, we're going to use Helm charts

- Helm charts give us a way to customize what we deploy

- Helm can also keep track of what we install

  (for easier uninstall and updates)
