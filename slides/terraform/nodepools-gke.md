## Node pools on GKE

⚠️ Disclaimer

I do not pretend to fully know and understand GKE's concepts and APIs.

I do not know their rationales and underlying implementations.

The techniques that I'm going to explain here work for me, but there
might be better ones.

---

## The default node pool

- Defined within the `google_container_cluster` resource

- Uses `node_config` block and `initial_node_count`

- If it's defined, it should be the only node pool!

- Disable it with either:

  `initial_node_count=1` and `remove_default_node_pool=true`

  *or*

  a dummy `node_pool` block and a `lifecycle` block to ignore changes to the `node_pool`

---

class: extra-details

## What's going on with the node pools?

When we run `terraform apply` (or, more accurately, `terraform plan`)...

- Terraform invokes the `google` provider to enumerate resources

- the provider lists the clusters and node pools

- it includes the node pools in the cluster resources

- ...even if they are declared separately

- Terraform notices these "new" node pools and wants to remove them

- we can tell Terraform to ignore these node pools with a `lifecycle` block

- I *think* that `remove_default_node_pool` achieves the same result 🤔

---

## Our new cluster resource

```tf
resource "google_container_cluster" "mycluster" {
  name               = "klstr"
  location           = "europe-north1-a"

  # We won't use that node pool but we have to declare it anyway.
  # It will remain empty so we don't have to worry about it.
  node_pool {
    name       = "builtin"
  }
  lifecycle {
    ignore_changes = [ node_pool ]
  }
}
```

---

## Our preemptible node pool

```tf
resource "google_container_node_pool" "preemptible" {
  name       = "preemptible"
  cluster    = google_container_cluster.mycluster.id
  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  node_config {
    preemptible  = true
  }
}
```

---

## Our normal node pool

```tf
resource "google_container_node_pool" "ondemand" {
  name       = "ondemand"
  cluster    = google_container_cluster.mycluster.id
  autoscaling {
    min_node_count = 0
    max_node_count = 5
  }
  node_config {
    preemptible  = false
  }
}
```

---

## Scale to zero

- It is possible to scale a single node pool to zero

- The cluster autoscaler will be able to scale up an empty node pool

  (and scale it back down to zero when it's not needed anymore)

- However, our cluster must have at least one node

  (the cluster autoscaler can't/won't work if we have zero node)

- Make sure that at least one pool has at least one node!

⚠️ Make sure to set `initial_node_count` to more than zero

⚠️ Setting `min_node_count` is not enough!

---

## Taints and labels

- We will typically use node selectors and tolerations to schedule pods

- The corresponding labels and taints must be set on the node pools

```tf
resource "google_container_node_pool" "bignodes" {
  ...
  node_config {
    machine_type = "n2-standard-4"
    labels = {
      expensive = ""
    }
    taint {
      key = "expensive"
      value = ""
      effect = "NO_SCHEDULE"
    }
  }
}
```
