This directory contains a Terraform configuration to deploy
a bunch of Kubernetes clusters on Scaleway, using their managed
Kubernetes (Kapsule).

To use it:

```bash
scw init
terraform init
terraform apply
cd stage2
terraform apply
```

Edit `variables.tf` to change the number of clusters.
