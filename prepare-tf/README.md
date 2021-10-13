This directory contains a Terraform configuration to deploy
a bunch of Kubernetes clusters on various cloud providers, using their respective managed Kubernetes products.

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

- Digital Ocean: `export DIGITALOCEAN_ACCESS_TOKEN=...`
  (check `~/.config/doctl/config.yaml` for the token)
- Linode: `export LINODE_TOKEN=...`
  (check `~/.config/linode-cli` for the token)
- Oracle Cloud: it should use `~/.oci/config`
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
rm stage/terraform.tfstate*
```
