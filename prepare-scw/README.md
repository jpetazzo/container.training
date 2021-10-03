This directory contains a Terraform configuration to deploy
a bunch of Kubernetes clusters on Scaleway, using their managed
Kubernetes (Kapsule).

To use it:

```bash
scw init
terraform init
export TF_VAR_how_many_clusters=5
export TF_VAR_nodes_per_cluster=2
terraform apply
cd stage2
terraform init
terraform apply
```
