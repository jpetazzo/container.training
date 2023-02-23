resource "linode_instance" "_" {
  count           = var.how_many_nodes
  label           = format("%s-%04d", var.prefix, count.index + 1)
  region          = var.location
  type            = var.size
  authorized_keys = local.authorized_keys
  image           = "linode/ubuntu22.04"
}

output "ip_addresses" {
  value = join("", formatlist("%s\n", linode_instance._.*.ip_address))
}
