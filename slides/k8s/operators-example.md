# Writing an tiny operator

- Let's look at a simple operator

- It does have:

  - a control loop
  - resource lifecycle management
  - basic logging

- It doesn't have:

  - CRDs (and therefore, resource versioning, conversion webhooks...)
  - advanced observability (metrics, Kubernetes Events)

---

## Use case

*When I push code to my source control system, I want that code
to be built into a container image, and that image to be deployed
in a staging environment. I want each branch/tag/commit (depending
on my needs) to be deployed into its specific Kubernetes Namespace.*

- The last part requires the CI/CD pipeline to manage Namespaces

- ...And permissions in these Namespaces

- This requires elevated privileges for the CI/CD pipeline

  (read: `cluster-admin`)

- If the CI/CD pipeline is compromised, this can lead to cluster compromise

- This can be a concern if the CI/CD pipeline is part of the repository

  (which is the default modus operandi with GitHub, GitLab, Bitbucket...)

---

## Proposed solution

- On-demand creation of Namespaces

- Creation is triggered by creating a ConfigMap in a dedicated Namespace

- Namespaces are set up with basic permissions

- Credentials are generated for each Namespace

- Credentials only give access to their Namespace

- Credentials are exposed back to the dedicated configuration Namespace

- Operator implemented as a shell script

---

## An operator in shell... Really?

- About 150 lines of code

  (including comments + white space)

- Performance doesn't matter

  - operator work will be a tiny fraction of CI/CD pipeline work

  - uses *watch* semantics to minimize control plane load

- Easy to understand, easy to audit, easy to tweak

---

## Show me the code!

- GitHub repository and documentation:

  https://github.com/jpetazzo/nsplease

- Operator source code:

  https://github.com/jpetazzo/nsplease/blob/main/nsplease.sh

---

## Main loop

```bash
  info "Waiting for ConfigMap events in $REQUESTS_NAMESPACE..."
  kubectl --namespace $REQUESTS_NAMESPACE get configmaps \
    --watch --output-watch-events -o json \
    | jq --unbuffered --raw-output '[.type,.object.metadata.name] | @tsv' \
    | while read TYPE NAMESPACE; do

      debug "Got event: $TYPE $NAMESPACE"
```

- `--watch` to avoid active-polling the control plane

- `--output-watch-events` to disregard e.g. resource deletion, edition

- `jq` to process JSON easily

---

## Resource ownership

- Check out the `kubectl patch` commands

- The created Namespace "owns" the corresponding ConfigMap and Secret

- This means that deleting the Namespace will delete the ConfigMap and Secret

- We don't need to watch for object deletion to clean up

- Clean up will we done automatically even if operator is not running

---

## Why no CRD?

- It's easier to create a ConfigMap

  (e.g. `kubectl create configmap --from-literal=` one-liner)

- We don't need the features of CRDs

  (schemas, printer columns, versioning...)

- “This CRD could have been a ConfigMap!”

  (this doesn't mean *all* CRDs could be ConfigMaps, of course)

---

## Discussion

- A lot of simple, yet efficient logic, can be implemented in shell scripts

- These can be used to prototype more complex operators

- Not all use-cases require CRDs

  (keep in mind that correct CRDs are *a lot* of work!)

- If the algorithms are correct, shell performance won't matter at all

  (but it will be difficult to keep a resource cache in shell)

- Improvement idea: this operator could generate *events*

  (visible with `kubectl get events` and `kubectl describe`)

???

:EN:- How to write a simple operator with shell scripts
:FR:- Comment écrire un opérateur simple en shell script
