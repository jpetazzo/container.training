# ArgoCD advanced patterns

- It's very common to deploy multiple apps or components following the same pattern

- Example: same app deployed to different namespaces (prod, preprod, staging)

- Example: same app deployed to different clusters (same; or regional clusters)

- Example: multiple apps using different Helm charts, each to its own namespace

- Example: multiple apps using the same Helm charts, different values YAML files

- Example: multiple apps deployed to multiple clusters (MxN)

- How should we deal with that?

---

## App of Apps

- ArgoCD Application that contains *more Applications* 

- Typical use-case: deploy a bunch of standard cluster components

  (example: Ingress controller, Prometheus exporters, log collectors, cert-manager...)

- That "App of Apps" can be a Helm chart ([example][argocd-app-of-apps-helm-example])

- It can leverage Helm advanced templating features

  (e.g. iterators, `range`, manipulating files...)

[argocd-app-of-apps-helm-example]: https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#helm-example

---

## Generated Apps, committed to repo

- Write scripts to generate ArgoCD Application manifests from some source of truth
 
  (scripts, more YAML files, database...)

- Commit the generated manifests

- Apply these manifests individually; or with an App of Apps

- Downsides:

  - each new app = need to run scripts, commit new files...

  - lots of potential repetitions in generated manifests

  - changes in the generator = big commit that is harder to analyze and review

---

## Generated Apps, not committed to repo

- What if we generated the ArgoCD Application manifests on the fly?

- This would avoid the downsides mentioned earlier

- But it would require to either:

  - do that in a custom CI/CD pipeline (Jenkins, GitHub Actions...), without ArgoCD

  - or integrate a custom "tool" (YAML generator) into ArgoCD

- *Doable, but quite complex!*

---

## Application Sets

- ArgoCD's native way to generate multiple Apps

- Application Set = ArgoCD Custom Resource containing a `template` and `generators`

- `template` = Application template evaluated with Go templating engine

- `generators` = iterators generating a list of environments

---

## Example

.small[
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-appset
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - list:
      elements:
      - repo: frontend
      - repo: backend
  template:
    metadata:
      name: "{{.repo}}"
    spec:
      project: default
      source:
        repoURL: "https://github.com/my-org/{{.repo}}.git"
        targetRevision: main
        path: deploy/manifests
      destination:
        server: "https://kubernetes.default.svc"
        namespace: "{{.repo}}"
```
]

---

## Some generators

- `list` = iterate over a pre-defined list of key/value maps

- `cluster` = deploy app on a list of clusters known to ArgoCD

- `git` = create one app for each file or directory found in a git repo

- `scm` = create one app for each repo detected on GitHub, Gitlab, Gitea, Bitbucket...

- `pullrequest` = ditto, but for pull requests

- `matrix` = combine multiple generators (MxN)

- `merge` = override some parameters

(See [ArgoCD documentation][argocd-generators] for detailed list.)

[argocd-generators]: https://argo-cd.readthedocs.io/en/latest/operator-manual/applicationset/Generators/

---

## Discussion

- Separation of concerns:

  - someone writes code
  - someone "containerizes" it (e.g. Dockerfiles)
  - someone writes e.g. Kubernetes manifests or Helm charts
  - someone deploys Kubernetes clusters
  - someone installs essential components (observability...)
  - (maybe someone deploys physical machines, or manages hypervisors)
  - someone applies Kubernetes manifests to clusters ⭐️
  - someone is on call on all that

⭐️ That's a part that can be automated with Application Sets.

But it requires someone to define how we organize code, repos, charts...

And some of these tasks will overlap multiple individuals / teams / orgs.

???

:EN:- ArgoCD advanced patterns
:FR:- Utilisation avancée d'ArgoCD
