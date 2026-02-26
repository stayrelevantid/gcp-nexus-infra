variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., prod, dev)"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "machine_type" {
  description = "The VM machine type"
  type        = string
  default     = "e2-micro"
}
