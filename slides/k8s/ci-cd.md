## Jenkins / Jenkins-X

- Multi-purpose CI

- Self-hosted CI for kubernetes

- Testing in namespace, feature branch

<!-- FIXME explain what the line above means? -->

.small[
```shell
curl -L "https://github.com/jenkins-x/jx/releases/download/v2.0.1103/jx-darwin-amd64.tar.gz" | tar xzv jx
./jx boot
```
]

---

## GitLab

- Repository + registry + CI/CD integrated all-in-one

```shell
helm repo add gitlab https://charts.gitlab.io/
helm install gitlab gitlab/gitlab
```

---
## Tekton / knative

- knative is serverless project from google

- Tekton leverages knative to run pipelines

---

## ArgoCD

.small[
```shell
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
]

<!-- 
FIXME I think we should add some details about these projects,
otherwise it feels like an enumeration
-->
