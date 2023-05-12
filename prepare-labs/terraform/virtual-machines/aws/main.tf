resource "aws_instance" "_" {
  for_each = local.nodes
  tags = {
    Name = each.value.node_name
  }
  instance_type     = each.value.node_size
  key_name          = aws_key_pair._.key_name
  ami               = data.aws_ami._.id
  source_dest_check = false
}

resource "aws_key_pair" "_" {
  key_name   = var.tag
  public_key = tls_private_key.ssh.public_key_openssh
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => aws_instance._[key].public_ip
  }
}

data "aws_ami" "_" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
