# Note: names and tags on GCP have to match a specific regex:
# (?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)
# In other words, they must start with a letter; and generally,
# we make them start with a number (year-month-day-etc, so 2025-...)
# so we prefix names and tags with "lab-" in this configuration.

resource "google_compute_instance" "_" {
  for_each     = local.nodes
  zone         = var.location
  name         = "lab-${each.value.node_name}"
  tags         = ["lab-${var.tag}"]
  machine_type = each.value.node_size
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata = {
    "ssh-keys" = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
  }
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => google_compute_instance._[key].network_interface[0].access_config[0].nat_ip
  }
}

resource "google_compute_firewall" "_" {
  name    = "lab-${var.tag}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["lab-${var.tag}"]
}
