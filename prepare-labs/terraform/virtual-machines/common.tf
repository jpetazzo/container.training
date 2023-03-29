# Note: on most modern systems (e.g. Fedora 33+, Ubuntu 22.04...)
# SSH authentication with RSA keys requires RSA-2 signatures.
# Terraform started supporting RSA-2 signatures somewhere around
# version 1.2, so we require 1.4 here to be safe.
# (See https://github.com/hashicorp/terraform/issues/30134)
terraform {
  required_version = ">= 1.4"
}

variable "tag" {
  type    = string
  default = "deployed-with-terraform"
}

variable "how_many_clusters" {
  type    = number
  default = 2
}

variable "nodes_per_cluster" {
  type    = number
  default = 3
}

variable "node_size" {
  type        = string
  default     = "M"
  description = "If this is S, M, or L, it will correspond to a VM with 2, 4, 8GB of RAM. If it's anything else, it will be a provider-specific instance type, e.g. g7-highmem-4 or c5n.xlarge."
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "id_rsa"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "id_rsa.pub"
  file_permission = "0600"
}

locals {
  nodes = {
    for cn in setproduct(
      range(1, 1 + var.how_many_clusters),
      range(1, 1 + var.nodes_per_cluster)
    ) :
    format("c%03dn%03d", cn[0], cn[1]) => {
      cluster_key  = format("c%03d", cn[0])
      cluster_name = format("%s-%03d", var.tag, cn[0])
      node_name    = format("%s-%03d-%03d", var.tag, cn[0], cn[1])
      node_size    = lookup(var.node_sizes, var.node_size, var.node_size)
    }
  }
}

resource "local_file" "ip_addresses" {
  content = join("", formatlist("%s\n", [
    for key, value in local.ip_addresses : value
  ]))
  filename        = "ips.txt"
  file_permission = "0600"
}

resource "local_file" "clusters" {
  content = join("", formatlist("%s\n", [
    for cid in range(1, 1 + var.how_many_clusters) :
    join(" ",
      [for nid in range(1, 1 + var.nodes_per_cluster) :
        local.ip_addresses[format("c%03dn%03d", cid, nid)]
  ])]))
  filename        = "clusters.txt"
  file_permission = "0600"
}
