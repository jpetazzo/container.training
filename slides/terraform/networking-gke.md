## [Networking]

- GKE has two networking modes: Routes-based and VPC-Native

- Let's see the differences between the two modes

[Networking]: https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips

---

## Routes-based

- Legacy mode

- Simpler (doesn't require specifying address ranges)

- Incompatible with some features

- It's the default mode when provisioning clusters with Terraform

- Terraform attribute: `networking_mode = "ROUTES"`

---

## VPC-Native

- New mode, recommended

- Default mode when provisioning with CLI or web console with recent versions

- Supports more features:

  - container-native load balancing (=direct routing to pods)
    <br/>(using NEG (Network Endpoint Group) Services)

  - private clusters (nodes without public IP addresses)

  - cluster interconnection...

- Terraform attribute: `networking_mode = "VPC_NATIVE"`

- Requires `ip_allocation_policy` block with `cluster_ipv4_cidr_block`

---

## Switching to routes-based networking

Add the following attributes in the `google_container_cluster` resource:

```tf
networking_mode = "VPC_NATIVE"
ip_allocation_policy {
  # This is the block that will be used for pods.
  cluster_ipv4_cidr_block = "10.0.0.0/12"
}
```

⚠️ This will destroy and re-create the cluster!

---

## Services

- Traffic path in routes-based clusters:

  client → google load balancer → node port → pod

- Traffic path in VPC-native clusters, with container-native load balancing:

  client → google load balancer → pod

---

## GKE ingress controller

- In routes-based clusters, Ingress Services must have a NodePort

  (because the load balancer can't connect directly to the pods)

- In VPC-native clusters, Ingress Services can be ClusterIP

- Try to create an Ingress in the cluster

  (you can leave the host part of the Ingress resource empty)

- Note: it will take a few minutes for the ingress address to show up
