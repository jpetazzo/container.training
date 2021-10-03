terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.1.0"
    }
  }
  required_version = ">= 0.14"
}

provider "scaleway" {
  #zone            = "nl-ams-1"
  #region          = "nl-ams"
  #project_id      = "7ee16446-7711-4171-a7c2-4bb6f0d4c4c8"
}

