# Exercise — Generating Ingress With Kyverno

When a Service gets created...

*(for instance, Service `blue` in Namespace `rainbow`)*

...Automatically generate an Ingress.

*(for instance, with host name `blue.rainbow.MYDOMAIN.COM`)*

---

## Goals

- Step 1: expose all services with a hard-coded domain name

- Step 2: only expose services that have a port named `http`

- Step 3: configure the domain name with a per-namespace ConfigMap

  (e.g. `kubectl create configmap ingress-domain-name --from-literal=domain=1.2.3.4.nip.io`)

---

## Hints

- We want to use a Kyverno `generate` ClusterPolicy

- For step 1, check [Generate Resources](https://kyverno.io/docs/writing-policies/generate/) documentation

- For step 2, check [Preconditions](https://kyverno.io/docs/writing-policies/preconditions/) documentation

- For step 3, check [External Data Sources](https://kyverno.io/docs/writing-policies/external-data-sources/) documentation
