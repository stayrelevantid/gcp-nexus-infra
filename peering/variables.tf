variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default GCP Region"
  type        = string
  default     = "asia-southeast2"
}
