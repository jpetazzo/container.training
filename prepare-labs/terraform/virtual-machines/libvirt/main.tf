# Base volume used by the vm as a backing_store
resource "libvirt_volume" "base" {
  name = "${var.tag}-base.qcow2"
  pool = var.libvirt_volume_pool
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.libvirt_base_image_url
    }
  }
}

# Per-node overlay volume (copy-on-write layer on top of the base image)
resource "libvirt_volume" "_" {
  for_each = local.nodes
  name     = "${each.value.node_name}.qcow2"
  pool     = var.libvirt_volume_pool
  target = {
    format = {
      type = "qcow2"
    }
  }
  # 30 GiB in bytes – same default used by other providers in this project
  # TODO: make it configurable for all providers
  capacity = 30 * 1024 * 1024 * 1024
  backing_store = {
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
}

# cloud-init seed ISO per node (user-data + network-config)
resource "libvirt_cloudinit_disk" "_" {
  for_each       = local.nodes
  name           = "${each.value.node_name}-cloudinit"
  user_data      = <<-EOF
    #cloud-config
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(tls_private_key.ssh.public_key_openssh)}
    package_update: false
    EOF
  meta_data      = <<-EOF
    instance-id: ${each.value.node_name}
    local-hostname: ${each.value.node_name}
    EOF
  network_config = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
        dhcp6: false
    EOF
}

# Upload the cloud-init ISO into the pool so it can be attached as a cdrom
resource "libvirt_volume" "cloudinit" {
  for_each = local.nodes
  name     = "${each.value.node_name}-cloudinit.iso"
  pool     = var.libvirt_volume_pool
  create = {
    content = {
      url = libvirt_cloudinit_disk._[each.key].path
    }
  }
}

# Optional dedicated NAT network (created when libvirt_network_name is empty)
resource "libvirt_network" "_" {
  count     = var.libvirt_network_name == "" ? 1 : 0
  name      = var.tag
  autostart = true
  forward = {
    mode = "nat"
  }
  #   bridge = {
  #     name = "virbr-${var.tag}"
  #   }
  domain = {
    name = var.libvirt_network_domain_name
  }
  ips = [
    {
      address = var.libvirt_network_ips_address
      prefix  = var.libvirt_network_ips_prefix
      dhcp = {
        ranges = [
          {
            start = var.libvirt_network_ips_dhcp_range_start
            end   = var.libvirt_network_ips_dhcp_range_end
          }
        ]
      }
    }
  ]
}

locals {
  network_name = (
    var.libvirt_network_name != "" ?
    var.libvirt_network_name :
    libvirt_network._[0].name
  )
}

# Virtual machine definition
resource "libvirt_domain" "_" {
  for_each = local.nodes

  name = each.value.node_name
  # memory is in KiB in the 0.9.x provider (mirrors libvirt XML)
  memory = tonumber(split(" ", each.value.node_size)[1]) * 1024
  vcpu   = tonumber(split(" ", each.value.node_size)[0])
  type   = "kvm"

  cpu = {
    mode = "host-passthrough"
    # check = "none"
    # migratable = "on"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot = {
      dev = ["hd"]
    }
  }

  features = {
    acpi = true
  }

  devices = {
    controllers = [
      {
        type  = "pci"
        model = "pcie-root"
      }
    ]

    disks = [
      {
        # Main disk for system
        source = {
          volume = {
            pool   = libvirt_volume._[each.key].pool
            volume = libvirt_volume._[each.key].name
          }
        }
        driver = {
          name    = "qemu"
          type    = "qcow2"
          cache   = "none"
          discard = "unmap"
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # For cloud-init
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit[each.key].pool
            volume = libvirt_volume.cloudinit[each.key].name
          }
        }
        target = {
          dev = "sdb"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        type = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = local.network_name
          }
        }
        wait_for_ip = {
          timeout = 300
          source  = "lease"
        }
      }
    ]
    # To get serial on console for virsh console --domain xxxxx
    serials = [
      {
        type = "pty"
        target = {
          type = "isa-serial"
          port = "0"
          model = {
            name = "isa-serial"
          }
        }
      }
    ]

    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = 0
        }
      }
    ]
    # Use the host /dev/urandom as vm random generator.
    rng = {
      model = "virtio"
      backend = {
        model = {
          random = "/dev/urandom"
        }
      }
    }
  }

  running = true
}

# IP addresses are queried via a data source in 0.9.x (no longer on the domain resource)
data "libvirt_domain_interface_addresses" "_" {
  for_each = local.nodes
  domain   = libvirt_domain._[each.key].name
  source   = "lease"
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => data.libvirt_domain_interface_addresses._[key].interfaces[0].addrs[0].addr
  }
}
