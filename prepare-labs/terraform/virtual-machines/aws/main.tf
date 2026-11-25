resource "aws_instance" "_" {
  for_each = local.nodes
  tags = {
    Name = each.value.node_name
  }
  instance_type     = each.value.node_size
  key_name          = aws_key_pair._.key_name
  ami               = data.aws_ami._.id
  source_dest_check = false
  # The node setup script from "labctl cloudinit", if the tag has one.
  # cloud-init runs it once, at first boot.
  user_data_base64 = fileexists("${path.module}/user_data.sh") ? base64gzip(file("${path.module}/user_data.sh")) : null
  lifecycle {
    # The script only matters at first boot. Don't change running VMs
    # if it is generated again.
    ignore_changes = [user_data, user_data_base64]
  }
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
