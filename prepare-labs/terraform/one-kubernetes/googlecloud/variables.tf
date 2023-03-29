locals {
  location = var.location != null ? var.location : "europe-north1-a"
  region   = replace(local.location, "/-[a-z]$/", "")
  # Unfortunately, the following line doesn't work
  # (that attribute just returns an empty string)
  # so we have to hard-code the project name.
  #project = data.google_client_config._.project
  project = "prepare-tf"
}

data "google_client_config" "_" {}

