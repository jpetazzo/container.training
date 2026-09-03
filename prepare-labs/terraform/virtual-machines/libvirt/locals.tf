locals {
  # Extract values from CIDR
  ip   = split("/", var.base_network)[0]
  mask = tonumber(split("/", var.base_network)[1])

  # Convert ip in 32 bits , base for increment
  octets = split(".", local.ip)
  ip_int = (
    tonumber(local.octets[0]) * 16777216 + # 256^3
    tonumber(local.octets[1]) * 65536 +    # 256^2
    tonumber(local.octets[2]) * 256 +      # 256^1
    tonumber(local.octets[3])              # 256^0
  )

  # On /24 bloc = 256 address
  block_size = 256

  # Creates 'how_many_clusters` networks adding 256 addresses
  clusters_subnets = [
    for i in range(var.how_many_clusters) : {
      index = i
      int   = local.ip_int + (i * local.block_size)
      cidr = format("%d.%d.%d.%d/24",
        floor((local.ip_int + i * local.block_size) / 16777216) % 256,
        floor((local.ip_int + i * local.block_size) / 65536) % 256,
        floor((local.ip_int + i * local.block_size) / 256) % 256,
        (local.ip_int + i * local.block_size) % 256,
      )
    }
  ]
  # Create clusetes
  clusters = {
    for cn in local.clusters_subnets :

    # According to local.nodes.cluster_key
    format("c%03d", cn.index + 1) => {
      cluster_name = format("%s-%03d", var.tag, cn.index + 1)

      network = {
        # 253 nodes are enought for testing cluster :)
        prefix     = 24
        dhcp_start = cidrhost(cn.cidr, 1)
        dhcp_end   = cidrhost(cn.cidr, var.nodes_per_cluster)
        gateway    = cidrhost(cn.cidr, 254)
      }
    }
  }
}
