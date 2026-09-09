# Managing our stack with `helmfile`

- We've installed a few things with Helm

- And others with raw YAML manifests

- Perhaps you've used Kustomize sometimes

- How can we automate all this? Make it reproducible?

---

## Requirements

- We want something that is *idempotent*

  = running it 1, 2, 3 times, should only install the stack once

- We want something that handles udpates

  = modifying / reconfiguring without restarting from scratch

- We want something that is configurable

  = with e.g. configuration files, environment variables...

- We want something that can handle *partial removals*

  = ability to remove one element without affecting the rest

- Inspiration: Terraform, Docker Compose...

---

## Shell scripts?

✅ Idempotent, thanks to `kubectl apply -f`, `helm upgrade --install`

✅ Handles updates (edit script, re-run)

✅ Configurable

❌ Partial removals

If we remove an element from our script, it won't be uninstalled automatically.

---

## Umbrella chart?

Helm chart with dependencies on other charts.

✅ Idempotent

✅ Handles updates

✅ Configurable (with Helm values: YAML files and `--set`)

✅ Partial removals

❌ Complex (requires to learn advanced Helm features)

❌ Requires everything to be a Helm chart (adds (lots of) boilerplate)

---

## Helmfile

https://github.com/helmfile/helmfile

✅ Idempotent

✅ Handles updates

✅ Configurable (with values files, environment variables, and more)

✅ Partial removals

✅ Fairly easy to get started

🐙 Sometimes feels like summoning unspeakable powers / staring down the abyss

---

## What `helmfile` can install

- Helm charts from remote Helm repositories

- Helm charts from remote git repositories

- Helm charts from local directories

- Kustomizations

- Directories with raw YAML manifests

---

## How `helmfile` works

- Everything is defined in a main `helmfile.yaml`

- That file defines:

  - `repositories` (remote Helm repositories)

  - `releases` (things to install: Charts, YAML...)

  - `environments` (optional: to specialize prod vs staging vs ...)

- Helm-style values file can be loaded in `enviroments`

- These values can then be used in the rest of the Helmfile

- Examples: [install essentials on a cluster][helmfile-ex-1], [run a Bento stack][helmfile-ex-2]

[helmfile-ex-1]: https://github.com/jpetazzo/beyond-load-balancers/blob/main/helmfile.yaml
[helmfile-ex-2]: https://github.com/jpetazzo/beyond-load-balancers/blob/main/bento/helmfile.yaml

---

## `helmfile` commands

- `helmfile init` (optional; downloads plugins if needed)

- `helmfile apply` (updates all releases that have changed)

- `helmfile sync` (updates all releases even if they haven't changed)

- `helmfile destroy` (guess!)

---

## Helmfile tips

As seen in [this example](https://github.com/jpetazzo/beyond-load-balancers/blob/main/bento/helmfile.yaml#L21):

- variables can be used to simplify the file

- configuration values and secrets can be loaded from external sources

  (Kubernetes Secrets, Vault... See [vals] for details)

- current namespace isn't exposed by default

- there's often more than one way to do it!

  (this particular section could be improved by using Bento `${...}`)

[vals]: https://github.com/helmfile/vals

???

## 🏗️ Let's build something!

- Write a helmfile (or two) to set up today's entire stack on a brand new cluster!

- Suggestion:

  - one helmfile for singleton, cluster components
    <br/>
    (All our operators: Prometheus, Grafana, KEDA, CNPG, RabbitMQ Operator)

  - one helmfile for the application stack
    <br/>
    (Bento, PostgreSQL cluster, RabbitMQ)

???

:EN:- Deploying with Helmfile
:FR:- Déployer avec Helmfile
