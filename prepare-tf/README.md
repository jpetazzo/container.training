This directory contains a Terraform configuration to deploy
a bunch of Kubernetes clusters on various cloud providers,
using their respective managed Kubernetes products.

To use it:

1. Select the provider you wish to use.

Change the `source` attribute of the `module "clusters"` section.
Check the content of the `modules` directory to see available choices.

```bash
vim main.tf
```

2. Initialize the provider.

```bash
terraform init
```

3. Configure provider authentication.

- Digital Ocean:
  ```bash
  export DIGITALOCEAN_ACCESS_TOKEN=$(grep ^access-token ~/.config/doctl/config.yaml | cut -d: -f2 | tr -d " ")
  ```

- Google Cloud Platform: you will need to create a project named `prepare-tf`
  and enable the relevant APIs for this project (sorry, if you're new to GCP,
  this sounds vague; but if you're familiar with it you know what to do; if you
  want to change the project name you can edit the Terraform configuration)

- Linode:
  ```bash
  export LINODE_TOKEN=$(grep ^token ~/.config/linode-cli | cut -d= -f2 | tr -d " ")
  ```

- Oracle Cloud: if you have setup the OCI CLI (and have a `~/.oci/config` config file),
  Terraform will use it by default

- Scaleway: run `scw init`

4. Decide how many clusters and how many nodes per clusters you want.

```bash
export TF_VAR_how_many_clusters=5
export TF_VAR_min_nodes_per_pool=2
# Optional (will enable autoscaler when available)
export TF_VAR_max_nodes_per_pool=4
# Optional (will only work on some providers)
export TF_VAR_enable_arm_pool=true
```

5. Provision clusters.

```bash
terraform apply
```

6. Perform second stage provisioning.

This will install a SSH server on the clusters.

```bash
cd stage2
terraform init
terraform apply
```

7. Obtain cluster connection information.

The following command shows connection information, one cluster per line, ready to copy-paste in a shared document or spreadsheet.

```bash
terraform output -json | jq -r 'to_entries[].value.value'
```

8. Destroy clusters.

```bash
cd ..
terraform destroy
```

9. Clean up stage2.

```bash
rm stage2/terraform.tfstate*
```
