variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default GCP Region"
  type        = string
  default     = "asia-southeast2"
}

variable "github_repo" {
  description = "Nama repositori GitHub dalam format owner/repo, contoh: octocat/my-repo"
  type        = string
}
