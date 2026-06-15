resource "openstack_compute_instance_v2" "talos" {
  for_each        = local.talos_nodes
  name            = each.value.node_name
  image_id        = openstack_images_image_v2.talos.image_id
  flavor_name     = each.value.node_size
  security_groups = [openstack_networking_secgroup_v2._.name]
  network {
    name = openstack_networking_network_v2._.name
  }
}

locals {
  talos_nodes_per_cluster = 3
  talos_schematic_id      = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
  talos_version           = "1.13.3"
}

resource "openstack_images_image_v2" "talos" {
  name             = "Talos ${local.talos_version} for ${var.tag}"
  image_source_url = "https://factory.talos.dev/image/${local.talos_schematic_id}/v${local.talos_version}/openstack-amd64.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
  properties = {
    os        = "talos"
    schematic = local.talos_schematic_id
    version   = local.talos_version
  }
}

resource "openstack_networking_secgroup_v2" "_" {
  name = var.tag
}

resource "openstack_networking_secgroup_rule_v2" "_" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2._.id
}

locals {
  talos_nodes = {
    for cn in setproduct(
      range(1, 1 + var.how_many_clusters),
      range(1, 1 + local.talos_nodes_per_cluster)
    ) :
    format("c%03dt%03d", cn[0], cn[1]) => {
      cluster_key  = format("c%03d", cn[0])
      cluster_name = format("%s-%03d", var.tag, cn[0])
      node_name    = format("%s-%03d-%03d", var.tag, cn[0], cn[1])
      node_size    = lookup(var.node_sizes, var.node_size, var.node_size)
    }
  }
}

resource "local_file" "talos" {
  content = join("", formatlist("%s\n", [
    for cid in range(1, 1 + var.how_many_clusters) :
    join("\t",
      [for nid in range(1, 1 + local.talos_nodes_per_cluster) :
        openstack_compute_instance_v2.talos[format("c%03dt%03d", cid, nid)].access_ip_v4
  ])]))
  filename        = "talos.tsv"
  file_permission = "0600"
}

