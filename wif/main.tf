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
    prefix = "env/wif"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Enable Required APIs
resource "google_project_service" "iamcredentials" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  project = var.project_id
  service = "sts.googleapis.com"
  disable_on_destroy = false
}

# 2. Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions authentication"
  depends_on                = [google_project_service.iamcredentials, google_project_service.sts]
}

# 3. Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "GitHub Actions Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  # Condition ensures only YOUR specific repo can authenticate
  # e.g., "assertion.repository == 'octocat/my-repo'"
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 4. Ambil informasi Service Account lama (Dari Fase 1)
data "google_service_account" "tf_sa" {
  account_id = "terraform-nexus"
  project    = var.project_id
}

# 5. Ikatkan Service Account tersebut dengan WIF Provider
resource "google_service_account_iam_member" "wif_sa_bind" {
  service_account_id = data.google_service_account.tf_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# Ouput ini akan dibutuhkan di GitHub Actions file
output "workload_identity_provider_name" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Gunakan nilai ini untuk 'workload_identity_provider' di GitHub Actions yml"
}

output "service_account_email" {
  value = data.google_service_account.tf_sa.email
  description = "Gunakan nilai ini untuk 'service_account' di GitHub Actions yml"
}
