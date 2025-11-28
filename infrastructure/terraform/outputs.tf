output "vm_external_ip" {
  value       = google_compute_address.static_ip.address
  description = "External IP address of the VM"
}

output "vm_name" {
  value       = google_compute_instance.lab_vm.name
  description = "Name of the VM instance"
}

output "zone" {
  value       = var.zone
  description = "Zone where the VM is located"
}

output "ssh_command" {
  value       = "gcloud compute ssh ${var.ssh_user}@${google_compute_instance.lab_vm.name} --zone=${var.zone}"
  description = "Command to SSH into the VM"
}

