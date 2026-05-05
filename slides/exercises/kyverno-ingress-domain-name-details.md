# Exercise — Generating Ingress With Kyverno

User story:


*As a developer
<br/>
(who knows about Services, but not Ingresses),*

*I want an Ingress to be created automatically
<br/>
(when I create a Service),*

*so that I can access my application on a simple URL
<br/>
(e.g. `http://<servicename>.<namespace>.<domain>`).*

---

## First goals

- Write a Kyverno policy to automatically generate Ingress resources from Services

- Create a Deployment + Service for a simple app (e.g. `jpetazzo/color`)

- Make sure that a corresponding Ingress is created when the Service is created

- Bonus: if an Ingress controller is installed, make sure this actually works

  (i.e. that the app can be accessed over e.g. http://blue.mynamespace.mydomain)

---

## Improving things

- What happens when deploying an app like DockerCoins? ([YAML][dockercoins-yaml])

- Improvements (in no specific order):

  - only create Ingresses for Services on well-known ports

  - or with specific labels / annotations

  - use the label / annotation in the Ingress host part

  - generate an HTTPRoute instead of (or in addition to) the Ingress resource

[dockercoins-yaml]: https://raw.githubusercontent.com/jpetazzo/container.training/refs/heads/main/k8s/dockercoins.yaml

---

## Stretch goals

- Implement a way to override the domain name in a specific Namespace

  - with a ConfigMap in that Namespace

  - or with a label or annotation on the Namespace

- Expose non-HTTP services with a TLSRoute

---

## Hints

- We want to use a Kyverno `generate` ClusterPolicy

- Useful Kyverno documentation pages:

  [Generate Resources](https://kyverno.io/docs/policy-types/cluster-policy/generate/)
  |
  [Preconditions](https://kyverno.io/docs/policy-types/cluster-policy/preconditions/)
  |
  [External Data Sources](https://kyverno.io/docs/policy-types/cluster-policy/external-data-sources/)
