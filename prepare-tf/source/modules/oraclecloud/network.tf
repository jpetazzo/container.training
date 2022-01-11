resource "oci_core_vcn" "_" {
  compartment_id = local.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "tf-vcn"
}

#
# On OCI, you can have either "public" or "private" subnets.
# In both cases, instances get addresses in the VCN CIDR block;
# but instances in "public" subnets also get a public address.
#
# Then, to enable communication to the outside world, you need:
# - for public subnets, an "internet gateway"
#   (will allow inbound and outbound traffic)
# - for private subnets, a "NAT gateway"
#   (will only allow outbound traffic)
# - optionally, for private subnets, a "service gateway"
#   (to access other OCI services, e.g. object store)
#
# In this configuration, we use public subnets, and since we
# need outside access, we add an internet gateway.
#
# Note that the default routing table in a VCN is empty, so we
# add the internet gateway to the default routing table.
# Similarly, the default security group in a VCN blocks almost
# everything, so we add a blanket rule in that security group.
#

resource "oci_core_internet_gateway" "_" {
  compartment_id = local.compartment_id
  display_name   = "tf-igw"
  vcn_id         = oci_core_vcn._.id
}

resource "oci_core_default_route_table" "_" {
  manage_default_resource_id = oci_core_vcn._.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway._.id
  }
}

resource "oci_core_default_security_list" "_" {
  manage_default_resource_id = oci_core_vcn._.default_security_list_id
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "controlplane" {
  compartment_id    = local.compartment_id
  cidr_block        = "10.0.254.0/24"
  vcn_id            = oci_core_vcn._.id
  display_name      = "tf-controlplane"
  route_table_id    = oci_core_default_route_table._.id
  security_list_ids = [oci_core_default_security_list._.id]
}

resource "oci_core_subnet" "nodes" {
  compartment_id    = local.compartment_id
  cidr_block        = "10.0.0.0/20"
  vcn_id            = oci_core_vcn._.id
  display_name      = "tf-nodes"
  route_table_id    = oci_core_default_route_table._.id
  security_list_ids = [oci_core_default_security_list._.id]
}

resource "oci_core_subnet" "loadbalancers" {
  compartment_id    = local.compartment_id
  cidr_block        = "10.0.96.0/20"
  vcn_id            = oci_core_vcn._.id
  display_name      = "tf-loadbalancers"
  route_table_id    = oci_core_default_route_table._.id
  security_list_ids = [oci_core_default_security_list._.id]
}
