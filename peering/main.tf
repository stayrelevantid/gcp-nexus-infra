terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "nexus-tf-state-stayrelevantid" 
    prefix = "env/peering"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------------------
# Data Sources: Mengambil data VPC Prod & Dev yang sudah dibuat sebelumnya
# ------------------------------------------------------------------------------
data "google_compute_network" "prod_vpc" {
  name = "nexus-vpc-prod"
}

data "google_compute_network" "dev_vpc" {
  name = "nexus-vpc-dev"
}

# ------------------------------------------------------------------------------
# VPC Peering
# ------------------------------------------------------------------------------
resource "google_compute_network_peering" "prod_to_dev" {
  name         = "peering-prod-to-dev"
  network      = data.google_compute_network.prod_vpc.self_link
  peer_network = data.google_compute_network.dev_vpc.self_link
}

resource "google_compute_network_peering" "dev_to_prod" {
  name         = "peering-dev-to-prod"
  network      = data.google_compute_network.dev_vpc.self_link
  peer_network = data.google_compute_network.prod_vpc.self_link
}
