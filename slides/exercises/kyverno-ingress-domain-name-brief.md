## Exercise — Generating Ingress With Kyverno

- When a Service gets created, automatically generate an Ingress

- Step 1: expose all services with a hard-coded domain name

- Step 2: only expose services that have a port named `http`

- Step 3: configure the domain name with a per-namespace ConfigMap
