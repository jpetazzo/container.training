## Provisioning Kubernetes resources

- We have a nice cluster deployed with Terraform

- Now let's deploy our apps on that cluster!

- There are a few gotchas, though:

  - no official provider to use YAML manifests

  - "stacking" issues

- Let's see what we can do!

---

## Creating Kubernetes resources

- Multiple providers are available

  - [`hashicorp/kubernetes`][kubernetes]: write K8S resources in HCL

  - [`hashicorp/helm`][helm]: install Helm charts

  - [`kbst/kustomization`][kustomization]: leverage kustomize

  - [`gavinbunney/kubectl`][kubectl]: use YAML manifests

- Disclaimer: I only have experience with the first two

[kubernetes]: https://registry.terraform.io/providers/hashicorp/kubernetes
[helm]: https://registry.terraform.io/providers/hashicorp/helm
[kustomization]: https://registry.terraform.io/providers/kbst/kustomization
[kubectl]: https://registry.terraform.io/providers/gavinbunney/kubectl

---

## `kubernetes` provider

```tf
resource "kubernetes_namespace" "hello" {
  metadata {
    name = "hello"
    labels = {
      foo = "bar"
    }
  }
}
```

There are tools to convert YAML to HCL, e.g. [k2tf](https://github.com/sl1pm4t/k2tf)

---

## `helm` provider

```tf
resource "helm_release" "metrics_server" {
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "metrics-server"
  version          = "5.8.8"
  name             = "metrics-server"
  namespace        = "metrics-server"
  create_namespace = true
  set {
    name  = "apiService.create"
    value = "true"
  }
  set {
    name  = "extraArgs.kubelet-insecure-tls"
    value = "true"
  }
  ...
}
```

---

## `kustomization`, `kubectl`

- Unofficial providers

- `kubectl` can use YAML manifests directly

- `kustomization` can use YAML manifests with a tiny bit of boilerplate

  (and thanks to kustomize, they can be tweaked very easily)

---

## Which one is best?

- It depends!

- Is it really Terraform's job to deploy apps?

- Maybe we should limit its role to deployment of add-ons?

  - for very simple scenarios, the `kubernetes` provider is enough

  - for more complex scenarios, there is often a Helm chart

- YMMV!

---

## In practice

1. Start with a Terraform configuration provisioning a cluster

2. Add a few Kubernetes resources, e.g. Deployment + LoadBalancer Service

3. `terraform apply` 

   (won't work because we must configure the Kubernetes provider)

4. Add `provider` block

   (check [provider docs][docs] for details)

5. `terraform apply`

   (if you get a connection to port 80 error, see next slides!)

[docs]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

---

## [Stacking]

- Terraform is creating a Kubernetes cluster

- This cluster is available only after provisioning (obviously!)

- `terraform apply` requires `terraform plan`, which requires `terraform refresh`

- `terraform refresh` requires access to the cluster

  (to check the state of the Kubernetes resources and figure out if they must be created)

- Furthermore, provider configuration can't depend on resource attributes

- Yet another "chicken-and-egg" problem!

[Stacking]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources

---

class: extra-details

## Provider configuration

According to the [Terraform documentation][providerdoc], when configuring providers:

*You can use expressions in the values of these configuration arguments, **but can only reference values that are known before the configuration is applied.** This means you can safely reference input variables, **but not attributes exported by resources** (with an exception for resource arguments that are specified directly in the configuration).*

This means that our `kubernetes` provider cannot use e.g. the endpoint address
provided by the resource that provisioned our Kubernetes cluster.

(e.g. `google_container_cluster`, `scaleway_k8s_cluster`, `linode_lke_cluster`...)

[providerdoc]: https://www.terraform.io/language/providers/configuration#provider-configuration-1

---

## Hack 1: targeted apply

- Create cluster and resources normally

- When updating the cluster, *target* it separately:

  `terraform apply -target=google_container_cluster.mycluster`

- Then apply the rest of the configuration:

  `terraform apply`

- Might work, but if you forget to do the targeted apply, you get weird errors

  (e.g. `dial tcp [::1]:80: connect: connection refused`)

---

## Hack 2: don't refresh

- Apply without refreshing first:

  `terraform apply -refresh-false`

- Might require a second `apply` afterwards

- To be honest: I didn't try this technique, so here be 🐉🐉🐉

---

## Hack 3: wipe secondary provider

- Remove the provider configuration from state:

  `terraform state rm module.kubeconfig`

- I've seen a few posts recommending it

- I don't believe in it 🤷🏻

---

## Better solution

- Two separate Terraform configurations

- First configuration manages the Kubernetes cluster

  ("first stage")

- Second configuration manages the apps on the cluster

  ("second stage")

- Now how do we pass the configuration between them?

---

## Hack: write kubeconfig

- First stage writes down a kubeconfig file

- Use `local` provider to create a [`local_file`][localdoc] resource

- Second stage uses that kubeconfig file

  (usable directly by the [`kubernetes`][k8sdoc] provider)

- Very convenient for quick work with `kubectl` too

- Pro-tip: don't use the `kubeconfig` file directly with `kubectl`!

- Merge it in `~/.kube/config` instead

[localdoc]: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
[k8sdoc]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#example-usage

---

## Better option: data sources

- Stage 1 creates the cluster

  (e.g. with a [`scaleway_k8s_cluster` resource][resource])

- Stage 2 retrieves the cluster

  (e.g. with a [`scaleway_k8s_cluster` *data source*][datasource])

- The kubernetes provider can then be configured with e.g.:
  ```tf
    provider "kubernetes" {
      host                   = data.scaleway_k8s_cluster._.host
      cluster_ca_certificate = data.scaleway_k8s_cluster._.cluster_ca_certificate
      token                  = data.scaleway_k8s_cluster._.token
    }
  ```

[resource]: https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_cluster
[datasource]: https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/k8s_cluster

---

## In practice

1. Separate the Kubernetes resources to a separate Terraform configuration

2. Update the `provider` block to use a data source

3. `terraform apply`

4. Bonus: add [output values][output] to show the Service external IP address

[output]: https://www.terraform.io/language/values/outputs
