terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "lab_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/../scripts/vm-setup.sh")

  tags = ["lab-experiment", "http-server", "https-server"]

  service_account {
    email  = google_service_account.lab_service_account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_address" "static_ip" {
  name   = "${var.vm_name}-ip"
  region = var.region
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vm_name}-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["lab-experiment"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.vm_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8081", "50051", "50059", "3306"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["lab-experiment"]
}

resource "google_service_account" "lab_service_account" {
  account_id   = "${var.vm_name}-sa"
  display_name = "Lab Experiment Service Account"
}

resource "google_project_iam_member" "service_account_iam" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.lab_service_account.email}"
}

