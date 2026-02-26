# ------------------------------------------------------------------------------
# 1. VPC Network (Custom Mode)
# ------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${var.vpc_name}-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
}

# ------------------------------------------------------------------------------
# 2. Subnet
# ------------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.vpc_name}-subnet-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# ------------------------------------------------------------------------------
# 3. Cloud Router & NAT (For outbound internet access without Public IPs)
# ------------------------------------------------------------------------------
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router-${var.environment}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat-${var.environment}"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}

# ------------------------------------------------------------------------------
# 4. Firewall Rules
# ------------------------------------------------------------------------------

# Allow SSH via Identity-Aware Proxy (IAP)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.vpc_name}-allow-iap-ssh-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP IP range
  target_tags   = ["allow-ssh"]
}

# Allow Internal traffic (ICMP, TCP, UDP within the VPC and peered VPCs)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/8"] # Assuming all internal IPs are within 10.0.0.0/8
}

# Allow HTTP traffic (Optional, for Nginx verification from within GCP or IAP tunneling)
resource "google_compute_firewall" "allow_http" {
  name    = "${var.vpc_name}-allow-http-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.0.0.0/8", "35.235.240.0/20"] 
  target_tags   = ["http-server"]
}

# ------------------------------------------------------------------------------
# 5. Compute Engine Instance (Nginx VM)
# ------------------------------------------------------------------------------
resource "google_compute_instance" "vm" {
  name         = "vm-${var.environment}"
  project      = var.project_id
  machine_type = var.machine_type
  zone         = "${var.region}-a" # Simplified for 1 zone
  allow_stopping_for_update = true

  tags = ["allow-ssh", "http-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    # No access_config block here ensures NO Public IP is created.
  }

  # Cost management & operational labels
  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  # Startup script to install Nginx securely (since Cloud NAT gives egress)
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Welcome to GCP-Nexus-Infra - ${var.environment}</h1>" > /var/www/html/index.html
  EOT
}
