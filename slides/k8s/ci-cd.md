## Jenkins / Jenkins-X

- Multi-purpose CI

- Self-hosted CI for kubernetes

- create a namespace per commit and apply manifests in the namespace
  </br>
  "A deploy per feature-branch"

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

## ArgoCD / flux

- Watch a git repository and apply changes to kubernetes

- provide UI to see changes, rollback

.small[
```shell
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
]

---

## Tekton / knative

- knative is serverless project from google

- Tekton leverages knative to run pipelines

- not really user friendly today, but stay tune for wrappers/products
