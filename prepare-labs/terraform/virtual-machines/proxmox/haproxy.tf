# If we deploy in IPv6-only environments, and the students don't have IPv6
# connectivity, we want to offer a way to connect anyway. Our solution is
# to generate an HAProxy configuration snippet, that can be copied to a
# DualStack machine which will act as a proxy to our IPv6 machines.
# Note that the snippet still has to be copied, so this is not a 100%
# streamlined solution!

locals {
  portmaps = {
    for key, value in local.nodes :
    (10000 + proxmox_virtual_environment_vm._[key].vm_id) => local.ip_addresses[key]
  }
}

resource "local_file" "haproxy" {
  filename        = "./${var.tag}.cfg"
  file_permission = "0644"
  content = join("\n", [for port, address in local.portmaps : <<-EOT
  frontend f${port}
    bind *:${port}
    default_backend b${port}
  backend b${port}
    mode tcp
    server s${port} [${address}]:22 maxconn 16
  EOT
  ])
}

resource "local_file" "sshproxy" {
  filename        = "sshproxy.txt"
  file_permission = "0644"
  content = join("", [
    for cid in range(1, 1 + var.how_many_clusters) :
    format("ssh -l k8s -p %d\n", proxmox_virtual_environment_vm._[format("c%03dn%03d", cid, 1)].vm_id + 10000)
  ])
}

