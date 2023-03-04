resource "digitalocean_droplet" "_" {
  count    = var.how_many_nodes
  name     = format("%s-%04d", var.prefix, count.index + 1)
  region   = var.location
  size     = var.size
  ssh_keys = [digitalocean_ssh_key._.id]
  image    = "ubuntu-22-04-x64"
}

resource "digitalocean_ssh_key" "_" {
  name       = var.prefix
  public_key = tls_private_key.ssh.public_key_openssh
}

output "ip_addresses" {
  value = join("", formatlist("%s\n", digitalocean_droplet._.*.ipv4_address))
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
