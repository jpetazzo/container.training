
output "networks" {
  value = [for n in local.clusters_subnets : n.cidr]
}

output "clusters" {
  value = [for n in local.clusters : n]
}

