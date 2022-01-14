⚠️ This is work in progress. The UX needs to be improved,
and the docs could be better.

This directory contains a Terraform configuration to deploy
a bunch of Kubernetes clusters on various cloud providers,
using their respective managed Kubernetes products.

## With shell wrapper

This is the recommended use. It makes it easy to start N clusters
on any provider. It will create a directory with a name like
`tag-YYYY-MM-DD-HH-MM-SS-SEED-PROVIDER`, copy the Terraform configuration
to that directory, then create the clusters using that configuration.

1. One-time setup: configure provider authentication for the provider(s) that you wish to use.

- Digital Ocean:
  ```bash
  doctl auth init
  ```

- Google Cloud Platform: you will need to create a project named `prepare-tf`
  and enable the relevant APIs for this project (sorry, if you're new to GCP,
  this sounds vague; but if you're familiar with it you know what to do; if you
  want to change the project name you can edit the Terraform configuration)

- Linode:
  ```bash
  linode-cli configure
  ```

- Oracle Cloud: FIXME
  (set up `oci` through the `oci-cli` Python package)

- Scaleway: run `scw init`

2. Optional: set number of clusters, cluster size, and region.

By default, 1 cluster will be configured, with 2 nodes, and auto-scaling up to 5 nodes.

If you want, you can override these parameters, with the following variables.

```bash
export TF_VAR_how_many_clusters=5
export TF_VAR_min_nodes_per_pool=2
export TF_VAR_max_nodes_per_pool=4
export TF_VAR_location=xxx
```

The `location` variable is optional. Each provider should have a default value.
The value of the `location` variable is provider-specific. Examples:

| Provider      | Example value     | How to see possible values
|---------------|-------------------|---------------------------
| Digital Ocean | `ams3`            | `doctl compute region list`
| Google Cloud  | `europe-north1-a` | `gcloud  compute zones list`
| Linode        | `eu-central`      | `linode-cli regions list`
| Oracle Cloud  | `eu-stockholm-1`  | `oci iam region list`

You can also specify multiple locations, and then they will be
used in round-robin fashion.

For example, with Google Cloud, since the default quotas are very
low (my account is limited to 8 public IP addresses per zone, and
my requests to increase that quota were denied) you can do the
following:

```bash
export TF_VAR_location=$(gcloud compute zones list --format=json | jq -r .[].name | grep ^europe)
```

Then when you apply, clusters will be created across all available
zones in Europe. (When I write this, there are 20+ zones in Europe,
so even with my quota, I can create 40 clusters.)

3. Run!

```bash
./run.sh <providername>
```

(If you don't specify a provider name, it will list available providers.)

4. Shutting down

Go to the directory that was created by the previous step (`tag-YYYY-MM...`)
and run `terraform destroy`.

You can also run `./clean.sh` which will destroy ALL clusters deployed by the previous run script.

## Without shell wrapper

Expert mode.

Useful to run steps sperarately, and/or when working on the Terraform configurations.

1. Select the provider you wish to use.

Go to the `source` directory and edit `main.tf`.

Change the `source` attribute of the `module "clusters"` section.

Check the content of the `modules` directory to see available choices.

2. Initialize the provider.

```bash
terraform init
```

3. Configure provider authentication.

See steps above, and add the following extra steps:

- Digital Coean:
  ```bash
  export DIGITALOCEAN_ACCESS_TOKEN=$(grep ^access-token ~/.config/doctl/config.yaml | cut -d: -f2 | tr -d " ")
  ```

- Linode:
  ```bash
  export LINODE_TOKEN=$(grep ^token ~/.config/linode-cli | cut -d= -f2 | tr -d " ")
  ```

4. Decide how many clusters and how many nodes per clusters you want.

5. Provision clusters.

```bash
terraform apply
```

6. Perform second stage provisioning.

This will install an SSH server on the clusters.

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
