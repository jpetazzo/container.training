## Jenkins/Jenkins-X

- Multi purpose CI

- Self-hosted CI for kubernetes

- testing in namespace, feature branch

.small[
```shell
$ curl -L "https://github.com/jenkins-x/jx/releases/download/v2.0.1103/jx-darwin-amd64.tar.gz" | tar xzv "jx"
$ ./jx boot
```
]

---
## Gitlab

- repository + registry + ci/cd integrated all-in-one

```shell
helm repo add gitlab https://charts.gitlab.io/
helm install gitlab gitlab/gitlab
```

---
## Tekton/knative

- knative is serverless project from google

- Tekton leverage knative to run pipeline

---
## ArgoCD

.small[
```shell
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
]
