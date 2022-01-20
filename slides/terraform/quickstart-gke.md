## GKE quick start

- Install Terraform and GCP SDK (`gcloud`)

- Authenticate with `gcloud auth login`

  (this is to use `gcloud` CLI commands)

- Authenticate with `gcloud auth application-default login`

  (this is so that Terraform can use the GCP API)

---

## Create project

- Create a project or use one of your existing ones

- Set the `GOOGLE_PROJECT` env var to the project name

  (this will be used by Terraform)

Note 1: there must be a billing account linked to the project.

Note 2: if the required APIs are not enabled on the project,
we will get error messages telling us "please enable that API"
when using the APIs for the first time. The error messages
should include instructions to do this one-time process.

---

## Create configuration

- Create empty directory

- Create a bunch of `.tf` files as shown in next slides

  (feel free to adjust the values!)

---

## Configuring providers

- We'll use the [google provider](https://registry.terraform.io/providers/hashicorp/google)

- It's an official provider (maintained by `hashicorp`)

- Which means that we don't have to add it explicitly to our configuration

  (`terraform init` will take care of it automatically)

- That'll simplify a tiny bit our "getting started" experience!

---

## `cluster.tf`

```tf
resource "google_container_cluster" "mycluster" {
  name = "klstr"
  location = "europe-north1-a"
  initial_node_count = 2
}
```

- [`google_container_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) is the *type* of the resource

- `mycluster` is the internal Terraform name for that resource

  (useful if we have multiple resources of that type)

- `location` can be a *zone* or a *region* (see next slides for details)

- don't forget `initial_node_count` otherwise we get a zero-node cluster 🙃

---

## Regional vs Zonal vs Multi-Zonal

- If `location` is a zone, we get a "zonal" cluster

  (control plane and nodes are in a single zone)

- If `location` is a region, we get a "regional" cluster

  (control plane and nodes span all zones in this region)

- In a region with Z zones, if we say we want N nodes...

  ...we get Z×N nodes

- We can also set `location` to be a zone, and set additional `node_locations`

- In that case we get a "multi-zonal" cluster with control plane in a single zone

---

## Standard vs [Autopilot]

- Standard clusters:

  - we manage nodes, node pools, etc.

  - we pay for control plane + nodes

- Autopilot clusters:

  - GKE manages nodes and node pools automatically

  - we cannot add/remove/change/SSH into nodes

  - all pods are in the "guaranteed" QoS class

  - we pay for the resources requested by the pods

[Autopilot]: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview

---

## Create the cluster

- Initialize providers
  ```bash
  terraform init
  ```

- Create the cluster:
  ```bash
  terraform apply
  ```

- We'll explain later what that "plan" thing is; just approve it for now!

- Check what happens if we run `terraform apply` again

- Problems? Check next slide for suggestions...

---

## Potential issues

```
Unknown token: 18:16 IDENT google_compute_network._.name
```

This seems to happen with older versions of Terraform (pre-1.0).
<br/>
Upgrade to a recent version. Use [tfenv] if you need to switch between versions.

```
Error: google_container_cluster.mycluster: : invalid or unknown key: networking_mode
```

This seems to happen with older versions of the `hashicorp/google` provider.
<br/>
We'll show on next slide how to get a newer version.

[tfenv]: https://github.com/tfutils/tfenv

---

## Pinning provider versions

To upgrade the `hashicorp/google` provider, add this to the configuration:

```tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.6.0"
    }
  }
}
```

Then run `terraform init -upgrade`, then try `terraform apply` again.

---

## Now what?

- Let's connect to the cluster

- Get the credentials for the cluster:
  ```bash
  gcloud container clusters get-credentials klstr --zone=europe-north1
  ```
  (Adjust the `zone` if you changed it earlier!)

- This will add the cluster to our `kubeconfig` file

- Deploy a simple app to the cluster

🎉
