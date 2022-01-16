# Terraform

“An open-source **infrastructure as code** software tool created by HashiCorp¹.”

- Other products in that space: Pulumi, Cloud Formation...

- Very rich ecosystem

- Supports many cloud providers

.footnote[¹Also creators of Consul, Nomad, Packer, Vagrant, Vault...]

---

## Infrastructure as code?

1. Write configuration files that describe resources, e.g.:

   - some GKE and Kapsule Kubernetes clusters
   - some S3 buckets
   - a bunch of Linode/Digital Ocean instances
   - ...and more

2. Run `terraform apply` to create all these things

3. Make changes to the configuration files

4. Run `terraform apply` again to create/update/delete resources

  (Vagrant, Packer, Consul, Vault, Nomad...)

5. Run `terraform destroy` to delete all these things

---

## What Terraform *is not*

- It's not a tool to abstract the differences between cloud providers

  (“I want to move my AWS workloads to Scaleway!”)

- It's not a configuration management tool

  (“I want to install and configure packages on my servers!”)

- It's not an application deployment tool

  (“I want to deploy a new build of my app!”

- It can be used for these things anyway (more or less succesfully)

---

## Vocabulary

- Configuration = a set of Terraform files

  - typically in HCL (HashiCorp Config Language), `.tf` extension

  - can also be JSON

- Resource = a thing that will be managed by Terraform

  - e.g. VM, cluster, load balancer...

- Provider = plugin to manage a family of resources

  - example: `google` provider to talk with GCP APIs

  - example: `tls` provider to generate keys
