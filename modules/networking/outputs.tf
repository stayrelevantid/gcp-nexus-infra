output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "subnet_id" {
  description = "The ID of the Subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "vm_name" {
  description = "The Name of the Nginx VM"
  value       = google_compute_instance.vm.name
}

output "vm_internal_ip" {
  description = "The internal IP address of the Nginx VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}
