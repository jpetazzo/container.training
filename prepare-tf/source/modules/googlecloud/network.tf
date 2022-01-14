/*
resource "google_compute_network" "_" {
  name    = var.cluster_name
  project = local.project
  # The default is to create subnets automatically.
  # However, this creates one subnet per zone in all regions,
  # which causes a quick exhaustion of the subnet quota.
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "_" {
  name          = var.cluster_name
  ip_cidr_range = "10.254.0.0/16"
  region        = local.region
  network       = google_compute_network._.id
  project       = local.project
}

resource "google_compute_router" "_" {
  name    = var.cluster_name
  region  = local.region
  network = google_compute_network._.name
  project = local.project
}

resource "google_compute_router_nat" "_" {
  name    = var.cluster_name
  router  = google_compute_router._.name
  region  = local.region
  project = local.project
  # Everyone in the network is allowed to NAT out.
  # (We would change this if we only wanted to allow specific subnets to NAT out.)
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  # Pick NAT addresses automatically.
  # (We would change this if we wanted to use specific addresses to NAT out.)
  nat_ip_allocate_option = "AUTO_ONLY"
}
*/