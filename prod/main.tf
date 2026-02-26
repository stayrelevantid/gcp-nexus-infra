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
    prefix = "env/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "networking" {
  source = "../modules/networking"

  project_id   = var.project_id
  region       = var.region
  environment  = "prod"
  vpc_name     = "nexus-vpc"
  subnet_cidr  = "10.1.0.0/24" # Prod subnet
  machine_type = "e2-small"    # Simulasi PR: Diubah dari e2-micro
}

output "prod_vm_internal_ip" {
  value = module.networking.vm_internal_ip
}
